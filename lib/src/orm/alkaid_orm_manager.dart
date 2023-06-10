import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:mirrors';
import 'package:alkaid/alkaid.dart';
import 'package:alkaid/orm.dart';
import 'package:alkaid/src/orm/alkaid_mysql_pool.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:yaml/yaml.dart';

///提供Mapping、连接管理、缓存等功能
///Mapping统一注入，为单例模式
///内置Mysql连接池，Mapping使用完成后，如果Mapping长时间没有使用，连接归还连接池，Mapping销毁
///连接池中的连接数要大于Mapping的数量才合理
class AlkaidOrmManager {
  late final AlkaidMySqlPool _pool;
  //collection中存放没有注入mysql连接的mapping
  final Map<Type,List<dynamic>> _collection = <Type,List<dynamic>>{};
  //该集合中的Mapping可以共享
  //如果使用次数为0,则回收
  final Map<Type,List<dynamic>> _usedCollection = <Type,List<dynamic>>{};
  final Map<Type,ClassMirror> _types = {};
  //该Mapping是否为_singleUsedCollection中的元素
  final Map<int,bool> _isSingle = {};
  //usedCollection中mapping被使用的数量
  final Map<int,int> _usedNumbers = {};
  //实际使用的数量，避免高并发出现错误
  final Map<Type,int> _identityCapacity = {};
  //等待队列
  final Queue<(Completer,Type,bool)> _waitQueue = Queue();
  //实现类的目录
  final String _implPath;
  final String _scanPath;
  //初始化每个Mapping创建的数量
  final int initMappingCapacity;
  //每个Mapping最多可以创建的实例
  final int maxMappingCapacity;
  static final Symbol _setConnectionSymbol = const Symbol('mysqlConnection=');
  static final Symbol _cleanConnectionSymbol = const Symbol('clearMySqlConnection');
  //每个timeout回收1/3的超出部分的mapping
  late final Timer _timer;

  AlkaidMySqlPool get pool => _pool;
  Map<Type,ClassMirror> get types => _types;

  AlkaidOrmManager(this._implPath,this._scanPath,DatabaseConfig databaseConfig,{
    required this.initMappingCapacity,required this.maxMappingCapacity,
    int? minCapacity,   int? maxCapacity,   Duration? timeout,
  }): _pool = AlkaidMySqlPool(databaseConfig,minCapacity: minCapacity,maxCapacity: maxCapacity,timeout: timeout,keepConnection: Duration(hours: 6)) {
    Duration time = timeout ?? Duration(seconds: 60);
    _timer = Timer.periodic(time, (timer) {
      //删除超出部分的1/3
      for(var list in _collection.values) {
        int beyond = list.length - maxMappingCapacity;
        if(beyond > 0) {
          for(int i = 0 ; i < beyond / 3 ; i++) {
            list.removeAt(i);
          }
        }
      }
    });
  }

  Future<void> init() async => _inject();

  ///reuse 为true，则从busy中取出mapping，与其他线程共享mapping
  Future<dynamic> getInstance(Type type,{bool reuse = true}) async {
    if(_types[type] == null) {
      throw AlkaidServerException('not found $type mapping');
    }

    //优先从usedCollection中获取实例，如果没有，而从collection获取实例并注入连接
    if(_collection[type]!.isNotEmpty) {
      var obj = _collection[type]!.removeAt(0);
      _identityCapacity[type] == null
          ? _identityCapacity[type] = 1
          : _identityCapacity[type] = _identityCapacity[type]! +1;
      MySQLConnection mySQLConnection = await pool.getConnection();
      reflect(obj).invoke(_setConnectionSymbol, [mySQLConnection]);
      _usedCollection[type]!.add(obj);
      _usedNumbers[obj.hashCode] = 1;
      return obj;
    } else if(maxMappingCapacity <= 0 || (_identityCapacity[type] != null && _identityCapacity[type]! < maxMappingCapacity)) {
      var obj = _types[type]!.newInstance(Symbol(''), []);
      _identityCapacity[type] = _identityCapacity[type]! + 1;
      MySQLConnection mySQLConnection = await pool.getConnection();
      obj.invoke(_setConnectionSymbol, [mySQLConnection]);
      _usedCollection[type]!.add(obj.reflectee);
      _usedNumbers[obj.reflectee.hashCode] = 1;
      return obj.reflectee;
    } else if(_usedCollection[type]!.isNotEmpty && reuse) {
      //寻找_usedConnection中使用次数最少的mapping
      int min = 100000000;
      int n = 0;
      for(int i = 0 ; i < _usedCollection[type]!.length ; i++) {
        if(_usedNumbers[_usedCollection[type]!.elementAt(i).hashCode]! <= min) {
          min = _usedNumbers[_usedCollection[type]![i].hashCode]!;
          n = i;
        }
      }
      _usedNumbers[_usedCollection[type]![n].hashCode] = min+1;
      return _usedCollection[type]![n];
    } else {
      //加入等待队列
      Completer completer = Completer();
      _waitQueue.addLast((completer,type,reuse));
      return completer.future;
    }
  }

  FutureOr<dynamic> getSingleInstance(Type type) async {
      var obj = _types[type]!.newInstance(Symbol(''), []);
      _isSingle[obj.hashCode] = true;
      await obj.invoke(_setConnectionSymbol, [await pool.getConnection()]).reflectee;
      return obj.reflectee;
  }

  ///回收Mapping
  ///不会立即将连接归还给连接池，只有当长时间没有使用才会归还连接
  Future<void> dispose(dynamic object,{cache = false}) async {
    if(_isSingle[object.hashCode] != null) {
      if(cache) {
        //获取mapping的使用次数
        ClassMirror classMirror = reflect(object).type;
        Type? type;
        for(var key in types.keys) {
          if(types[key] == classMirror) {
            type = key;
            break;
          }
        }
        if(type == null) {
          throw AlkaidServerException('$object 类型错误!');
        }
        _usedCollection[type]!.add(object);
        _usedNumbers[object.hashCode] = 0;
        if(_waitQueue.isNotEmpty) {
          for(int i = 0 ; i < _waitQueue.length ; i++) {
            if(_waitQueue.elementAt(i).$2 == type) {
              var member = _waitQueue.elementAt(i);
              _waitQueue.remove(member);
              _usedNumbers[object.hashCode] = 1;
              member.$1.complete(object);
              break;
            }
          }
        }
        return ;
      } else {
        _isSingle.remove(object.hashCode);
        //归还连接
        MySQLConnection mySQLConnection =  reflect(object)
            .invoke(_cleanConnectionSymbol, [])
            .reflectee;
        pool.dispose(mySQLConnection);
        object = null;
        return;
      }
    }

    //获取mapping的使用次数
    InstanceMirror instanceMirror = reflect(object);
    ClassMirror classMirror = instanceMirror.type;
    Type? type;
    for(var key in types.keys) {
      if(types[key] == classMirror) {
        type = key;
        break;
      }
    }

    if(type == null) {
      throw AlkaidServerException('$object 类型错误!');
    }

    if(cache) {
      _usedNumbers[object.hashCode] = _usedNumbers[object.hashCode]! - 1;
      if(_waitQueue.isNotEmpty) {
        for(int i = 0 ; i < _waitQueue.length ; i++) {
          if(_waitQueue.elementAt(i).$2 == type) {
            var member = _waitQueue.elementAt(i);
            if(member.$3 == true) {
              _waitQueue.remove(member);
              _usedNumbers[object.hashCode] =
                  _usedNumbers[object.hashCode]! + 1;
              member.$1.complete(object);
              break;
            } else {
              if(_usedNumbers[object.hashCode] == 0) {
                _waitQueue.remove(member);
                _usedNumbers[object.hashCode] = 1;
                member.$1.complete(object);
                break;
              } else {
                continue;
              }
            }
          }
        }
      }
      return ;
    }
    for(int i = 0 ; i < _usedCollection[type]!.length ; i++) {
      var ele = _usedCollection[type]![i];
      if(ele.hashCode == object.hashCode) {
        int n = _usedNumbers[object.hashCode]!;
        --n;
        if(n == 0) {
          //等待队列非空，则直接将mapping给等待的线程
          if(_waitQueue.isNotEmpty) {
            for(int i = 0 ; i < _waitQueue.length ; i++) {
              if(_waitQueue.elementAt(i).$2 == type) {
                var member = _waitQueue.elementAt(i);
                _waitQueue.remove(member);
                _usedNumbers[object.hashCode] = 1;
                member.$1.complete(object);
                return ;
              }
            }
          }
          //将资源归还池
          _usedNumbers.remove(object.hashCode);
          _usedCollection[type]!.removeAt(i);
          _identityCapacity[type]  = _identityCapacity[type]! - 1;
          _collection[type]!.add(object);
          MySQLConnection mySQLConnection = instanceMirror.invoke(_cleanConnectionSymbol, []).reflectee;
          pool.dispose(mySQLConnection);
          object = null;
          break;
        } else {
          _usedNumbers[object.hashCode] = n;
          for(int i = 0 ; i < _waitQueue.length ; i++) {
            if(_waitQueue.elementAt(i).$2 == type && _waitQueue.elementAt(i).$3 == true) {
              var member = _waitQueue.elementAt(i);
              _waitQueue.remove(member);
              _usedNumbers[object.hashCode] = n +1;
              member.$1.complete(object);
              break;
            }
          }
        }
        break;
      }
    }
  }


  //抽象类的实现类需要以抽象类的名字startWith
  void _inject() async {

    await pool.init();

    if(_types.isEmpty) {
      await _scan();
    }


    for(var type in _types.keys) {
      _collection[type] ??= [];
      _usedCollection[type] ??= [];
    }

    final directory = Directory(_implPath);
    YamlMap yamlMap = loadYaml(File('pubspec.yaml').readAsStringSync());
    String packageName = yamlMap['name'];
    final uris = <Uri>[];

     for(var entity in directory.listSync(recursive: true,followLinks: false)) {
      if(entity is File && entity.path.endsWith('.dart')) {
        // print(entity.path);
        uris.add(Uri.parse('package:$packageName${entity.path.replaceAll('lib', '')}'));
      }
    }

    IsolateMirror isolateMirror = currentMirrorSystem().isolate;
     var orm = List<Type>.from(types.keys);
    for(var uri in uris) {
      LibraryMirror libraryMirror = await isolateMirror.loadUri(uri);
      libraryMirror.declarations.forEach((symbol, declaration) {
        //寻找实现类
        if(declaration is ClassMirror && !MirrorSystem.getName(symbol).contains('AlkaidORM')) {
          var name = MirrorSystem.getName(symbol);
          int n = -1;
          for(int i = 0 ; i < orm.length ; i++) {
            var abstractName = MirrorSystem.getName(reflectType(orm[i]).simpleName);
            if(name.startsWith(abstractName)) {
              n = i;
              break;
            }
          }

          if(n >= 0) {
            Type type = orm.removeAt(n);
            _types[type] = declaration;
            for(int i = 0 ; i < initMappingCapacity ; i++) {
              var instance = declaration
                  .newInstance(Symbol(
                  ''), [])
                  .reflectee;
              _collection[type]!.add(instance);
            }
          }
        }
      });
    }

  }


  //判断是否为实现类
  //b 是否为 a的实现类
  bool _isImpl(ClassMirror a,ClassMirror b) {
    bool result = true;
    a.declarations.forEach((symbol, declaration) {
      if(declaration is MethodMirror && _check(declaration)) {
        if(!b.declarations.keys.contains(symbol)) {
          result = false;
        }
      }
    });
    return result;
  }

  bool _check(MethodMirror methodMirror) {
    return methodMirror.isAbstract && !methodMirror.isGetter && !methodMirror.isSetter
        &&  !methodMirror.isConstructor && methodMirror.simpleName != Symbol('noSuchMethod');
  }


  Future<void> _scan() async {
    final directory = Directory(_scanPath);
    YamlMap yamlMap = loadYaml(File('pubspec.yaml').readAsStringSync());
    String packageName = yamlMap['name'];
    final library = <LibraryMirror>[];
    final uris = <Uri>[];
    IsolateMirror isolateMirror = currentMirrorSystem().isolate;
     for(var entity in directory.listSync(recursive: true,followLinks: false)) {
      if(entity is File && entity.path.endsWith('.dart') && !entity.path.endsWith('_impl.dart')) {
        uris.add(Uri.parse('package:$packageName${entity.path.replaceAll('lib', '')}'));
      }
    }


    for(var uri in uris) {
      LibraryMirror libraryMirror = await isolateMirror.loadUri(uri);
      libraryMirror.declarations.forEach((symbol, declaration) {
        //寻找@Table类，生成抽象Mapping
        if(declaration is ClassMirror && declaration.metadata.any((element) => element.reflectee is ORM)) {
          _types[declaration.reflectedType] = declaration;
        }
      });
    }
  }

  void close() {
    //需要等待所有任务完成
    //监听_userNumber的状态
    // Timer.periodic(Duration(seconds: 1), (timer) {
    //   if(_usedNumbers.isEmpty) {
    //
    //   } else if(timer.tick >=  60) {
    //     //强制关闭
    //     _usedCollection.forEach((key, value) {
    //       _collection[key].add(value);
    //     });
    //     _usedCollection.clear();
    //     _collection.clear();
    //
    //   }
    // });

    _pool.close();
    _usedCollection.clear();
    _timer.cancel();
    _usedNumbers.clear();
    _collection.clear();
    _types.clear();
    _isSingle.clear();

  }
}


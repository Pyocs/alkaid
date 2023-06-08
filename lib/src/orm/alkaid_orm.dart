import 'dart:mirrors';
import 'package:mysql_client/mysql_client.dart';
import '../../alkaid.dart';
import 'preparedstmt_cache.dart';


///使用注解进行ORM操作的混合类
final _valueRegExp =  RegExp(r'VALUES|values');
mixin AlkaidORM {
  MySQLConnection? _mySQLConnection;

   final PreparedStmtCache _cache = PreparedStmtCache();

  late bool autocommit = false ;
  ///是否开启缓存
  bool canCache = true;

  bool _hasList = false;

  TypeMirror listTypeMirror = reflectType(List);
  bool get hasMysqlConnection => _mySQLConnection != null;

  set mysqlConnection(MySQLConnection? mySQLConnection) {
    _mySQLConnection = mySQLConnection;
  }

  MySQLConnection clearMySqlConnection() {
    if(hasMysqlConnection) {
      MySQLConnection mySQLConnection = _mySQLConnection!;
      _mySQLConnection = null;
      return mySQLConnection;
    } else {
      throw 'mysqlConnection not init';
    }
  }

  //框架初始化时调用
  // void init(MySQLConnection? mySQLConnection,{bo) {
  //   _mySQLConnection = mySQLConnection;
  //   if(cache != null) {
  //     canCache = cache;
  //   }
  //   _cache = PreparedStmtCache();
  // }

  ///开启临时事务
  Future<void> startTransactionMixin() async {
    await _mySQLConnection!.execute('start transaction');
  }

  ///提交事务
  Future<void> commitMixin() async {
    await _mySQLConnection!.execute('commit');
  }

  ///回滚事务
  Future<void> rollbackMixin() async {
    await _mySQLConnection!.execute('rollback');
  }

  ///设置事务的中间点
  Future<void> savepointMixin(String name) async {
    await _mySQLConnection!.execute('savepoint $name');
  }

  ///回滚到指定中间点
  Future<void> rollbackToMixin(String name) async {
    await _mySQLConnection!.execute('rollback to $name');
  }

  ///设置本次连接开启事务，及手动提交
  Future<void> startAutocommitMixin() async{
    if(!autocommit) {
      await _mySQLConnection!.execute('set autocommit = 0');
      autocommit = true;
    }
  }

  Future<void> closeAutocommitMixin() async {
    if(autocommit) {
      await _mySQLConnection!.execute('set autocommit = 1');
      autocommit = false;
    }
  }

  bool isAutocommitMixin() {
    return autocommit;
  }

  Future<void> closeMixin()  async {
    await _cache.clear();
    await _mySQLConnection!.close();
  }

  bool _isOrm(ClassMirror classMirror) {
    if(classMirror.reflectedType == Select || classMirror.reflectedType == Insert
        || classMirror.reflectedType == Delete || classMirror.reflectedType == Update) {
      return true;
    }
    return false;
  }

  ///是否单一的对象(String,int,float,...)
  bool _isSingleObject(dynamic object) {
    // return object.runtimeType == String || object.runtimeType == int
    //     || object.runtimeType == double || object.runtimeType == DateTime
    //     || object.runtimeType == List<int>;

    return object == String || object == int
        || object == double || object == DateTime ||
        object.runtimeType == String || object.runtimeType == int
        || object.runtimeType == double || object.runtimeType == DateTime
        || (object.runtimeType == List<int> ) || (  object == List<int>);
  }

  dynamic selectMixin(Select select,List value) async {
    PreparedStmt? preparedStmt;
    if(canCache) {
      preparedStmt = _cache.getValue(select.sql);
    }
    if(preparedStmt == null) {
      preparedStmt = await _mySQLConnection!.prepare(select.sql);
      if (canCache) {
        _cache.addValue(select.sql, preparedStmt);
      }
    }
    IResultSet iResultSet = await preparedStmt.execute(value);

    //获取行数
    var rowCount = iResultSet.numOfRows;

    Map<String,String?>? ownerMap;
    //自定义的映射关系
    if(select.autoInject) {
      ownerMap = null;
    } else {
      ownerMap = select.fields;
    }

    if(rowCount == 0) {
      return null;
    }
    if(rowCount == 1) {
      return  _injectSingle(select.object, iResultSet.rows.first.assoc(), ownerMap);
    } else {
      var list =  List.generate(rowCount, (index) {
        return _injectSingle(select.object, iResultSet.rows.elementAt(index).assoc(), ownerMap);
      });
      if(_hasList) {
        _hasList = false;
        _deleteRepeatObject(list, select.object);
      }
      return list;
    }
  }

  dynamic insertMixin(Insert insert,List value) async {
    //insert into address values (?,?,?,?)
    String sql = insert.sql;

    // List result = List.filled(sql.substring(sql.lastIndexOf(RegExp(r'VALUES|values'))).split(',').length , null);
    List result = [];
    //是否为全部插入,values前是否有()
    bool allInsert;
    if(sql.substring(0,sql.lastIndexOf(_valueRegExp)).contains('(') || sql.substring(0,sql.lastIndexOf(_valueRegExp)).contains(')')) {
      allInsert = false;
    } else {
      allInsert = true;
    }

    //如果为全部插入
    if(allInsert) {
      //判断是否为自定义的Class,如果是，则取出全部变量，如果不是，则依次将变量放入result中
      if(value.every(_isSingleObject)) {
        result.addAll(value);
      } else {
        //通过反射获取该对象全部的变量
        for(var ele in value) {
          var instance = reflect(ele);
          var classMirror = instance.type;
          classMirror.declarations.forEach((symbol, declaration) {
            if(declaration is VariableMirror && _isSingleObject(declaration.type.reflectedType) && !declaration.type.isAssignableTo(listTypeMirror)) {
              result.add(instance.getField(symbol).reflectee);
            }
          });
        }
      }
    } //按需插入，驼峰命名法映射
    else {
      if(value.every(_isSingleObject)) {
        result.addAll(value);
      } else {
        //获取插入的字段名称
        List insertNames = _getSpecifiedField(sql);

        //将名称转换
        for(int i = 0 ; i < insertNames.length ; i++) {
          insertNames[i] = _transformName(insertNames[i]);
        }

        //获取变量列表，同名映射
        for(var ele in value) {
          var instance = reflect(ele);
          var classMirror = instance.type;
          classMirror.declarations.forEach((symbol, declaration) {
            if(declaration is VariableMirror && insertNames.contains(MirrorSystem.getName(symbol))) {
              result.add(instance.getField(symbol).reflectee);
            }
          });
        }
      }
    }

    //判断values()中的变量个数，删除result中多余的变量
    List<String> elements = sql.substring(sql.lastIndexOf(_valueRegExp)).replaceAll(')', '').replaceAll('(', '').replaceAll(_valueRegExp, '').split(',');
    for(int i = 0 ; i < elements.length ; i++) {
      if(elements[i] != '?') {
        result.removeAt(i);
      }
    }

    PreparedStmt? preparedStmt;
    if(canCache) {
      preparedStmt =  _cache.getValue(sql);
    }
    try {
      if(preparedStmt == null) {
        preparedStmt = await _mySQLConnection!.prepare(sql);
        if (canCache) {
          _cache.addValue(sql, preparedStmt);
        }
      }
      IResultSet iResultSet = await preparedStmt.execute(result);
      if(insert.resultSet != null && insert.resultSet == true) {
        return iResultSet;
      }
      return true;
    } catch(err) {
      print(err);
      return false;
    }
  }

  dynamic updateMixin(Update update,List value) async {
    //update address_inf set addr_detail = ?,owner_id = ? where addr_id = ?
    String sql = update.sql;

    List result = [];

    //获取set字段
    List<String> setNames = _getSpecifiedField(sql);

    //获取where字段
    List<String> whereNames = _getWhereFields(sql);

    bool target = false;

    if(value.every(_isSingleObject)) {
      result.addAll(value);
    } else {
      for(int i = 0 ; i < setNames.length ;i++) {
        setNames[i] = _transformName(setNames[i]);

        for(int j = 0 ; j < value.length ; j++) {

          var instance = reflect(value[j]);
          var classMirror = instance.type;
          for(int k = 0;k<classMirror.declarations.values.length;k++) {
            if(classMirror.declarations.values.toList()[k] is VariableMirror && MirrorSystem.getName(classMirror.declarations.values.toList()[k].simpleName) == setNames[i]) {
              result.add(instance.getField(classMirror.declarations.keys.toList()[k]).reflectee);
              target = true;
              break;
            }
          }
          if(target == true) {
            target = false;
            break;
          }
        }
      }

      for(int i = 0 ;i < whereNames.length ; i++) {
        whereNames[i] = _transformName(whereNames[i]);
        for(int j = 0 ; j < value.length ; j++) {

          var instance = reflect(value[j]);
          var classMirror = instance.type;
          for(int k = 0;k<classMirror.declarations.values.length;k++) {
            if(classMirror.declarations.values.toList()[k] is VariableMirror && MirrorSystem.getName(classMirror.declarations.values.toList()[k].simpleName) == whereNames[i]) {
              result.add(instance.getField(classMirror.declarations.keys.toList()[k]).reflectee);
              target = true;
              break;
            }
          }
          if(target == true) {
            target = false;
            break;
          }
        }
      }
    }

    PreparedStmt? preparedStmt;
    if(canCache) {
      preparedStmt =  _cache.getValue(sql);
    }
    try {
      if(preparedStmt == null) {
        preparedStmt = await _mySQLConnection!.prepare(sql);
        if (canCache) {
          _cache.addValue(sql, preparedStmt);
        }
      }
      IResultSet iResultSet = await preparedStmt.execute(result);
      if(update.resultSet != null && update.resultSet == true) {
        return iResultSet;
      }
      return true;
    } catch(err) {
      print(err);
      return false;
    }
  }

  dynamic deleteMixin(Delete delete ,List value) async {
    String sql = delete.sql;
    List result = [];

    if(value.every(_isSingleObject)) {
      result.addAll(value);
    } else {
      //通过反射获取该对象全部的变量
      for(var ele in value) {
        var instance = reflect(ele);
        var classMirror = instance.type;
        classMirror.declarations.forEach((symbol, declaration) {
          if(declaration is VariableMirror && _isSingleObject(declaration.type.reflectedType) && !declaration.type.isAssignableTo(listTypeMirror)) {
            result.add(instance.getField(symbol).reflectee);
          }
        });
      }
    }

    PreparedStmt? preparedStmt;
    if(canCache) {
      preparedStmt =  _cache.getValue(sql);
    }
    try {
      if(preparedStmt == null) {
        preparedStmt ??= await _mySQLConnection!.prepare(sql);
        if(canCache) {
          _cache.addValue(sql, preparedStmt);
        }
      }
      IResultSet iResultSet = await preparedStmt.execute(result);
      if(delete.resultSet != null && delete.resultSet == true) {
        return iResultSet;
      }
      return true;
    } catch(err) {
      print(err);
      return false;
    }
  }


  ///序列化单一对象
  dynamic _injectSingle(Type type,Map<String, String?> map ,Map? ownerMap) {
    var object = reflectClass(type);
    var instance = object.newInstance(Symbol(''),[]);
    // var row = iResultSet.rows.first;


    //是否有Future变量(复杂映射)
    //包含其他符合类型
    bool hasFuture = false;

    //是否有List
    bool hasList = false;


    //同名映射
    if(ownerMap == null) {
      object.declarations.forEach((symbol, declaration) {
        if(declaration is VariableMirror) {
          if (!_isSingleObject(declaration.type.reflectedType)) {
            if(declaration.type.isAssignableTo(listTypeMirror)) {
              hasList = true;
            } else {
              hasFuture = true;
            }
          } else {
            String name = _reverseTransformName(MirrorSystem.getName(symbol));
            // instance.setField(symbol, map[name]);
            instance.setField(symbol,
                _objectFormat(map[name], declaration.type.reflectedType));
            map.remove(name);
          }
        }
      });
    }

    //自定义映射
    else {
      var list = ownerMap.keys.toList();
      object.declarations.forEach((symbol, declaration) {
        if(declaration is VariableMirror) {
          if (!_isSingleObject(declaration.type.reflectedType)) {
            if(declaration.type.isAssignableTo(listTypeMirror)) {
              hasList = true;
            } else {
              hasFuture = true;
            }
          } else {
            //获取的是class中的变量名
            String name = MirrorSystem.getName(symbol);
            // mysql => class
            // ownerMap.forEach((key, value) {
            //   if (value == name) {
            //     name = key;
            //   }
            // });

            for(int i = 0 ; i < list.length ; i++) {
              if(ownerMap[list[i]] == name) {
                name = list[i];
                break;
              }
            }

            // instance.setField(symbol, map[name]);
            instance.setField(symbol,
                _objectFormat(map[name], declaration.type.reflectedType));

            // ownerMap.removeWhere((key, value) => value.toString() == name);
            map.remove(name);

          }
        }
      });
    }

    //包含单一的复合变量
    if(hasFuture && map.isNotEmpty) {
      List<TypeMirror> types = [];
      //获取Future泛型类型
      object.declarations.forEach((symbol, declaration) {
        if(declaration is VariableMirror && !_isSingleObject(declaration.type.reflectedType)) {
          //泛型类型
          // types.add(declaration.type.typeArguments.first);
          types.add(declaration.type);
        }
      });
      //将剩下的map列反序列化到types的Type中
      for(var type in types) {
        // String name = MirrorSystem.getName(type.simpleName);
        // instance.setField(Symbol('${name[0].toLowerCase()}${name.substring(1,name.length)}'), _injectSingle(type.reflectedType, map, ownerMap));
        instance.setField(_getSymbol(object, type)!, _injectSingle(type.reflectedType, map, ownerMap));
      }
    }

    //包含List
    //提起改行中属于复合变量的字段，并将属于该对象变量的字段写入缓存
    //
    if(hasList && map.isNotEmpty) {
      // List<InstanceMirror> types = [];
      Map<InstanceMirror,TypeMirror> types = {};
      object.declarations.forEach((symbol, declaration) {
        if(declaration is VariableMirror && declaration.type.isAssignableTo(listTypeMirror)) {
          //获取List
          // types.add(instance.getField(symbol));
          types.addEntries({instance.getField(symbol):declaration.type}.entries);
        }
      });

      types.forEach((listInstance, type) {
        //序列化该行中的复合对象
        var t = _injectSingle(type.typeArguments.first.reflectedType, map, ownerMap);
        listInstance.invoke(Symbol('add'), [t]);
      });
      _hasList = true;
    }

    return instance.reflectee;
  }

  ///删除重复元素
  void _deleteRepeatObject(List lists,Type object) {
    /*
      遍历所有list ，找出除了List、复合变量以外的所有变量，
      如果相同，则将后者的List添加到前者，然后删除后者
     */
    // ClassMirror classMirror = reflectClass(object);

    //存储变量，用于比较是否为同一个对象
    List<List> temp = [];

    int k = 0;
    for(int i = 0 ; i < lists.length ; i++) {
      bool isOwner = true;
      //k 表示当前temp保存到第几行数据
      //j 用于表示当前遍历的列
      int j = 0;
      //a 用来记录它与哪个相同
      int a = 0;
      InstanceMirror instanceMirror = reflect(lists[i]);
      ClassMirror clazz = instanceMirror.type;
      //z表示当前遍历的行
      int z = 0;
      clazz.declarations.forEach((symbol, declaration) {
        if(declaration is VariableMirror && _isSingleObject(declaration.type.reflectedType) && !declaration.type.isAssignableTo(listTypeMirror)) {
          if(i == 0) {
            if(temp.length <= k) {
              temp.add([]);
            }
            temp[k].add(instanceMirror.getField(symbol).reflectee);
          } else {
            while(z <= k) {
              if(temp[z][j] != instanceMirror.getField(symbol).reflectee) {
                ++z;
                if(z > k) {
                  isOwner = false;
                  break;
                }
              } else {
                a = z;
                break;
              }
            }
          }
        }
        j++;
      });

      //取出复合对象，放入前者，删除后者
      if(isOwner && i != 0) {
        clazz.declarations.forEach((symbol, declaration) {
          if(declaration is VariableMirror && declaration.type.isAssignableTo(listTypeMirror)) {
            //取出list内的全部元素
            var tempList = instanceMirror.getField(symbol).reflectee as List;
            //获取前一个instance
            InstanceMirror previousInstance = reflect(lists[a]);
            InstanceMirror nowListInstance = previousInstance.getField(symbol);

            //添加到前者
            nowListInstance.invoke(Symbol('addAll'),[tempList]);
            //删除后者
            lists.removeAt(i);
            //相当于i不变
            --i;
          }
        });
      } else if(isOwner == false && i != 0){
        isOwner = true;
        //对象不同，将它的值添加到temp中
        k++;
        if(temp.length <= k) {
          temp.add([]);
        }
        if(i != 0) {
          clazz.declarations.forEach((symbol, declaration) {
            if (declaration is VariableMirror &&
                _isSingleObject(declaration.type.reflectedType)) {
              temp[k].add(instanceMirror
                  .getField(symbol)
                  .reflectee);
            }
          });
        }
      }
    }
    //内存回收
    temp.clear();
  }

  ///根据type获取变量名称
  Symbol? _getSymbol(ClassMirror classMirror,TypeMirror typeMirror) {
    Symbol? symbol;
    for(var key in classMirror.declarations.keys) {
      if(classMirror.declarations[key] is VariableMirror && ((classMirror.declarations[key]) as VariableMirror).type == typeMirror ) {
        symbol = key;
        break;
      }
    }
    return symbol;
  }


  ///获取插入、查询,更新的字段
  List<String> _getSpecifiedField(String mappingSql) {
    if(mappingSql == '') {
      return [];
    } else if(mappingSql.contains('INSERT') || mappingSql.contains('insert')) {
      return mappingSql.substring(
          mappingSql.indexOf('('),
          mappingSql.indexOf(')')
      )
          .replaceAll('(', '')
          .replaceAll(')', '')
          .trim()
          .split(',');
    } else if(mappingSql.contains('SELECT') || mappingSql.contains('select')) {
      return mappingSql.substring(
          mappingSql.indexOf(RegExp(r'SELECT|select')),
          mappingSql.indexOf(RegExp(r'FROM|from'))
      )
          .replaceAll(RegExp(r'SELECT|select'), '')
          .replaceAll(RegExp(r'FROM|from'), '')
          .trim()
          .split(',');
    } else  if(mappingSql.contains('UPDATE') || mappingSql.contains('update')) {
      return mappingSql.substring(
          mappingSql.indexOf(RegExp(r'SET|set')),
          mappingSql.contains(RegExp(r'WHERE|where')) ? mappingSql.indexOf(RegExp(r'WHERE|where')) : mappingSql.length
      )
          .replaceAll(RegExp(r'SET|set'), '')
          .replaceAll(RegExp(r'WHERE|where'), '')
          .trim()
          .replaceAll('=', '')
          .replaceAll('?', '')
          .trim()
          .split(',')
          .map((e) => e.trim())
          .toList();
    } else {
      return [];
    }
  }

  ///获取where字段
  List<String> _getWhereFields(String sql) {
    // RegExp regExp = RegExp(r'(\w+ = ?)|(\w+)');
    if(!sql.contains(RegExp(r'WHERE|where'))) {
      return [];
    }
    sql = sql.substring(sql.indexOf(RegExp(r'WHERE|where'))).replaceAll(RegExp(r'WHERE|where'), '');
    sql = sql
        .replaceAll('=', '')
        .replaceAll('?', '')
        .replaceAll('>=', '')
        .replaceAll('<=', '')
        .replaceAll(RegExp(r'AND|and'), '')
        .replaceAll(RegExp(r'OR|or'), '');

    var p = sql.split(' ');
    p.removeWhere((element) => element == '');
    return p;
  }

  ///驼峰命名转换
  String _transformName(String name) {
    String filedName;
    var ts = name.split('_');
    if(ts.length == 1) {
      filedName = ts.first;
    } else {
      filedName = ts.first;
      for(int i = 1; i < ts.length ; i++) {
        filedName += '${ts[i][0].toUpperCase()}${ts[i].substring(1)}';
      }
    }
    return filedName;
  }


  String _reverseTransformName(String name) {
    String result = '';
    for(int i = 0 ; i< name.length ; i++) {
      //如果是大写
      if(name[i].toUpperCase() == name[i]) {
        result += '_';
      }
      result += name[i].toLowerCase();
    }
    return result;
  }

  dynamic _objectFormat(dynamic own,dynamic target) {
    if(own.runtimeType == target) {
      return own;
    }
    switch(target) {
      case int:       return int.parse(own);
      case double:    return double.parse(own);
      case DateTime:  return DateTime.parse(own);
      case List: return own.toString().codeUnits;
      default: return null;
    }
  }
}
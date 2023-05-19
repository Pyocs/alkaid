import 'dart:io';
import 'dart:mirrors';
import 'package:yaml/yaml.dart';

import '../../../alkaid.dart';

///根据domain 生成 dao dao具有ORM注解
///根据abstract class 生成实现类


class MappingGeneration {
  //文件路径

  //文件最后保存的路径
  //默认保存到当前文件夹下的 impl/


  MappingGeneration();

  Future<void> start() async {
    final directory = Directory('lib');
    YamlMap yamlMap = loadYaml(File('pubspec.yaml').readAsStringSync());
    String packageName = yamlMap['name'];
    final uris = <Uri>[];

    await for(var entity in directory.list(recursive: true,followLinks: false)) {
      if(entity is File && entity.path.contains('.dart')) {
        // print(entity.path);
        uris.add(Uri.parse('package:$packageName${entity.path.replaceAll('lib', '')}'));
      }
    }

    IsolateMirror isolateMirror = currentMirrorSystem().isolate;
    for(var uri in uris) {
      LibraryMirror libraryMirror = await isolateMirror.loadUri(uri);
      libraryMirror.declarations.forEach((symbol, declaration) {
        //寻找具有ORM注解的抽象类
        if(declaration is ClassMirror && declaration.isAbstract
            && declaration.metadata.any((element) => element.reflectee is ORM)) {
          var t = uri.path.split('/');
          t.replaceRange(0, 1, ['lib']);
          print(t.join('/'));
          _init(symbol,declaration,t.join('/'));
          _addMethod(t.join('/'));
        }
      });
    }
  }


  ///生成抽象的Mapping
  ///classMirror 对应domain文件
  ///[path] dao保存的路径
  void _generationAbstractMapping(ClassMirror classMirror ,String path) {
    File file = File(path);
    String abstractClassName = '${MirrorSystem.getName(classMirror.simpleName)}Mapping';

    file.writeAsStringSync('''
import 'package:hello/modules/annotation/database_annotation.dart';

@ORM()
abstract class $abstractClassName {
}
''');

  }


  ///生成实现类
  //filePath抽象类文件路径
  Future<void> _init(Symbol symbol,ClassMirror classMirror,final String filePath) async {
    //生成文件路径
    String path = '';
    var splits = filePath.split('/');
    for (int i = 0; i < splits.length; i++) {
      if (i == splits.length - 1) {
        path += 'impl/';
        break;
      } else {
        path += '${splits[i]}/';
      }
    }
    String fileName = '$path${splits.last.replaceAll('.dart', '_impl.dart')}';
    File file = File(fileName);
    Directory directory = Directory(path);
    if(!directory.existsSync()) {
      directory.createSync();
    }
    if(!file.existsSync()) {
      file.createSync();
    }

    file.writeAsStringSync(_generation(symbol, classMirror, splits.last));
  }

  String _generation(Symbol symbol, ClassMirror classMirror,String fileName) {
    String result = '';
    String className = MirrorSystem.getName(symbol);
    result += '''
import 'dart:mirrors';
import '../$fileName';
import 'package:hello/modules/orm/alkaid_orm.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:hello/modules/annotation/database_annotation.dart';

class ${className}Impl with AlkaidORM implements $className {

  ${className}Impl(MySQLConnection mySQLConnection,{bool? cache}) {
    init(mySQLConnection,cache: cache);
  }
  
    @override
  dynamic noSuchMethod(Invocation invocation) async {
    String name = MirrorSystem.getName(invocation.memberName);
    if(name == 'startTransaction') {
      return await startAutocommitMixin();
    } else if(name == 'commit') {
      return await commitMixin();
    } else if(name == 'rollback') {
      return await rollbackMixin();
    } else if(name == 'savepoint') {
      return await savepointMixin(invocation.positionalArguments.first);
    } else if(name == 'rollbackTo') {
      return await rollbackToMixin(invocation.positionalArguments.first);
    } else if(name == 'startAutocommit') {
      return await startAutocommitMixin();
    } else if(name == 'closeAutocommit') {
      return await closeAutocommitMixin();
    } else if(name == 'isAutocommit') {
      return  isAutocommitMixin();
    } else if(name == 'close') {
      return await closeMixin();
    }

    var owner = reflectClass($className);
    for (var element in owner.declarations[invocation.memberName]!.metadata) {
      switch(element.reflectee.runtimeType) {
        case(Select):
          Select select = element.reflectee;
          return await selectMixin(select, invocation.positionalArguments);
        case(Insert):
          Insert insert = element.reflectee;
          return insertMixin(insert, invocation.positionalArguments);
        case(Update):
          Update update = element.reflectee;
          return updateMixin(update, invocation.positionalArguments);
        case(Delete):
          Delete delete = element.reflectee;
          return deleteMixin(delete, invocation.positionalArguments);
      }
    }
  }
}  
''';
    return result;
  }

  ///修改现有的抽象类文件，添加事务函数
  void _addMethod(String path) async {
    File file = File(path);
    var rs = await  file.open(mode: FileMode.append);
    //利用栈找到插入的位置
    List<int> stack = [];

    List<int> index = [];

    for(int i = 0 ; i < file.lengthSync() ; i++) {
      rs.setPositionSync(i);
      int value = rs.readByteSync();
      //找到 {
      if(value == 123) {
        stack.add(value);
      }
      //找到 }
      else if(value == 125) {
        if(stack.last == 123) {
          //出栈
          stack.removeLast();
          if(stack.isEmpty) {
            //找到class的末尾
            index.add(i);
          }
        } else {
          stack.add(value);
        }
      }
    }

    for(var i in index) {
      rs.setPositionSync(i - 1);
      rs.writeStringSync('''\n
  Future<void> startTransaction();
  Future<void> commit();
  Future<void> rollback();
  Future<void> savepoint(String name);
  Future<void> rollbackTo(String name);
  Future<void> startAutocommit();
  Future<void> closeAutocommit();
  bool isAutocommit();
  Future<void> close();
}
 ''');
    }
    rs.closeSync();
  }
}
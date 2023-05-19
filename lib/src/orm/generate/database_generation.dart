import 'dart:io';
import 'dart:async';
import 'dart:mirrors';
import 'package:yaml/yaml.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:io/ansi.dart';

import '../../../alkaid.dart';
import '../config/database_generation_meta.dart';

///数据库生成器
///扫描lib下所有带有@Table,并按照order生成
///如果没有order,则按照默认顺序生成
class DatabaseGeneration {
  late final MySQLConnection _mySQLConnection;

  late final String _databaseName;

  late final bool _deleteDatabase;
  ///生成的sql语句
  final List<DatabaseGenerationMeta> _sqlList = [];

  void _add(DatabaseGenerationMeta databaseGenerationMeta) {
    _sqlList.add(databaseGenerationMeta);
    _sqlList.sort((first,second) {
      return first.order - second.order;
    });
  }

  DatabaseGeneration(this._mySQLConnection,this._databaseName,{bool? deleteDatabase}) {
    if(deleteDatabase == null) {
      _deleteDatabase = true;
    } else {
      _deleteDatabase = deleteDatabase;
    }
  }

  Future<void> start() async {
    if(_deleteDatabase) {
      await _init();
    }
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
      _metaScan(libraryMirror);
    }

    for(var i = 0 ; i< _sqlList.length ; i++) {
      print(yellow.wrap(_sqlList[i].sql));
      await _mysqlGeneration(_sqlList[i].sql);
    }
    _mySQLConnection.close();
  }

  Future<void> _init() async {
    String sql ='DROP DATABASE IF EXISTS $_databaseName';
    await _mysqlGeneration(sql);
    await _mysqlGeneration('CREATE DATABASE $_databaseName');
    await _mysqlGeneration('USE $_databaseName');
  }

  //扫描注解
  Future<void> _metaScan(LibraryMirror libraryMirror) async {
    //如果class包含@Table
    for (var classMirror in libraryMirror.declarations.values) {
      if(classMirror is ClassMirror) {
        Table? table;
        for (var element in classMirror.metadata) {
          if(element.reflectee is Table) {
            table = element.reflectee;
            break;
          }
        }
        if(table == null) {
          return ;
        }

        List<Row> rows = [];

        //字段名(外键约束)
        List<String> names = [];

        //获取该table中的所有行
        classMirror.declarations.forEach((symbol, declaration) {
          if(declaration is VariableMirror && declaration.metadata.any((element) => element.reflectee is Row)) {
            Row row = declaration.metadata.firstWhere((element) => element.reflectee is Row).reflectee as Row;
            rows.add(row);
            if(row.constraint != null) {
              //如果包含外键约束，将该字段名添加到names中
              if(row.constraint!.any((element) => element is FOREIGN)) {
                // names.add(MirrorSystem.getName(declaration.simpleName));
                names.add(row.rowName);
              }
            }
          }
        });
        //将按照table row 生成sql语句
        _generationSql(table, rows,names);
      }
    }
  }

  //name 字段名
  void  _generationSql(Table table,List<Row> rows,List<String> names) {
    String sql;
    sql = 'CREATE TABLE ${table.tableName} ( ';

    //外键约束必须在所有字段定义后添加
    String foreignString = '';

    for(var row in rows) {
      //字段名
      String rowName = row.rowName;

      //字段数据类型
      String type = row.type;

      //行sql
      String rowSql;

      //约束
      String constraint = '';

      if(row.constraint != null) {
        for (var ele in row.constraint!) {
          switch(ele.runtimeType) {
            case PRIMARY:       constraint += ' PRIMARY KEY ';  break;
            case NOTNULL:       constraint += ' NOT NULL ';     break;
            case AUTOINCREMENT: constraint += ' AUTO_INCREMENT ';break;
            case UNIQUE:        constraint += ' UNIQUE ';       break;
            case DEFAULT:
              DEFAULT def = ele as DEFAULT;
              constraint += ' DEFAULT("${def.value}") ';
              break;
            case FOREIGN:
              FOREIGN foreign = ele as FOREIGN;
              assert(names.isNotEmpty);
              foreignString += 'FOREIGN KEY (${names.first}) REFERENCES ${foreign.tableName}(${foreign.field}) , ';
              names.remove(names.first);
              break;
            default:throw ArgumentError();
          }
        }
      }
      //该行的生成语句
      rowSql = ' $rowName $type  $constraint';
      sql += ' $rowSql, ';
      constraint = constraint.trim();
    }
    sql = sql.trim();
    sql = '$sql $foreignString'.trim();
    if(sql.endsWith(',')) {
      sql =  sql.substring(0,sql.length -1);
    }

    sql += ' );';
    // print(sql);
    _add(DatabaseGenerationMeta(table.order ?? 1, sql.toString()));
  }


  //数据库生成
  Future<void> _mysqlGeneration(String sql) async {
    // if(!_mySQLConnection.connected) {
    //   await _mySQLConnection.connect();
    // }

    await _mySQLConnection.execute(sql);
    return Future.value();
  }
}
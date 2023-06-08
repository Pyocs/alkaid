import 'dart:io';
import 'package:yaml/yaml.dart';

//序列化到数据库后需要删除的文件名称
List<String> removeFileNames = [];

///将YAML文件序列化成class
class YamlToOrm {

  ///filePath：文件路径
  ///outPath： 输出路径
  Future<void> start(String filePath,String outPath) async {
    if(outPath.endsWith('/')) {
      outPath = outPath.substring(0,outPath.length -1);
    }
    //保存路径为domain
    // if(!outPath.endsWith('domain')) {
    //   outPath += '/domain';
    // }

    YamlMap yamlMap = await loadYaml(File(filePath).readAsStringSync());

    String databaseName = yamlMap['database']['name'];

    //解析tables
    List tables = yamlMap['database']['tables'];

    //渲染orm
    for (var ele in tables) {
      _Table table = _processTable(ele['table']);
      var temp = table.name.split('_');
      //默认会删除最后一个_后面的内容
      temp.removeLast();
      String fileName = temp.join('_');
      Directory directory = Directory(outPath);
      if(!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      File file = File('$outPath/$fileName.dart');
      file.writeAsStringSync(_rendering(table));
      if (table.serial == false) {
        removeFileNames.add('$outPath/$fileName.dart');
      }
    }

    for(var element in removeFileNames) {
      File file = File(element);
      if(file.existsSync()) {
        file.deleteSync();
      }
    }
  }


  String _rendering(_Table table) {
    //className默认取出最后一个_后面的内容
    String className = '';

    var names = table.name.split('_');
    names.remove(names.last);

    for (var str in names) {
      for (int i = 0; i < str.length; i++) {
        if (i == 0) {
          className += str[i].toUpperCase();
        } else {
          className += str[i];
        }
      }
    }

    String result = '''
import 'package:alkaid/alkaid.dart';

@Table('${table.name}',order: ${table.order})
class $className  {\n
''';

    //dart字段名称
    List<String> varNames = [];

    //sql字段名称
    List<String> sqlNames = [];

    for (var row in table.rows) {
      bool isNull;
      if (row.constraint.contains('not')) {
        isNull = false;
      } else {
        isNull = true;
      }

      String constraints = '';
      for (var constraint in row.constraint) {
        switch (constraint) {
          case("primary"):
            constraints += 'PRIMARY(),';
            break;
          case("not"):
            constraints += 'NOTNULL(),';
            break;
          case("auto"):
            constraints += 'AUTOINCREMENT(),';
            break;
          case("unique"):
            constraints += 'UNIQUE(),';
            break;
        }
        if (constraint.contains('default')) {
          constraints += constraint.replaceAll('default', 'DEFAULT')
              .replaceAll('(', '("')
              .replaceAll(')', '")');
          constraints += ",";
        }
        if (constraint.contains('foreign')) {
          constraints += constraint
              .replaceAll('foreign', 'FOREIGN')
              .replaceAll('(', '("')
              .replaceAll(')', '")')
              .replaceAll(',', '","');
          constraints += ",";
        }
      }
      if (constraints.endsWith(',')) {
        constraints = constraints.substring(0, constraints.length - 1);
      }

      String varType;
      if (row.type.contains('int')) {
        varType = 'int';
      } else if (row.type.contains('varchar')) {
        varType = 'String';
      } else if (row.type.contains('float') || row.type.contains('double')) {
        varType = 'double';
      } else if (row.type.contains('date')) {
        varType = 'DateTime';
      } else if(row.type.contains('timestamp')) {
        varType = 'DateTime';
      } else {
        varType = 'dynamic';
      }

      if (isNull && varType != 'dynamic') {
        varType += '?';
      }

      result += '''
  @Row('${row.type}', '${row.name}',constraint:[$constraints])
  late $varType ${_transformName(row.name)};
  
''';
      varNames.add(_transformName(row.name));
      sqlNames.add(row.name);
    }

    //复合对象
    if (table.contain != null) {
      for (var ele in table.contain!) {
        var objectName = ele.substring(0, ele.indexOf('('));
        var num = ele.replaceAll(objectName, '').replaceAll('(', '').replaceAll(
            ')', '');
        var clazzName = '${objectName[0].toUpperCase()}${objectName.substring(
            1, objectName.length)}';
        if (num == 'one') {
          result += '''
  late $clazzName $objectName;\n
''';
        } else if (num == 'many') {
          result += '''
  List<$clazzName> $objectName = [];\n
''';
        }
      }
    }

    //构造器函数
    String constructorString = '$className.intact(';

    for (int i = 0; i < varNames.length; i++) {
      if (i == varNames.length - 1) {
        constructorString += 'this.${varNames[i]});';
      } else {
        constructorString += 'this.${varNames[i]},';
      }
    }


    result += '''
  $className();\n
  $constructorString\n
${_toString(varNames)}
}
''';
    /*
        result += '''
  $className();\n
  $constructorString\n
${_hashCodeToString(varNames, sqlNames)}\n
${_toString(varNames)}
}
''';
     */
    return result;
  }


  ///生成hashCodeToString函数
  String _hashCodeToString(List<String> varNames, List<String> names) {
    String result = '''
  @override
  Map<int,String> hashCodeToString() {
    return { 
''';
    for (int i = 0; i < varNames.length; i++) {
      if (i == varNames.length - 1) {
        result += '''
      ${varNames[i]}.hashCode:'${names[i]}'
''';
      } else {
        result += '''
      ${varNames[i]}.hashCode:'${names[i]}',
''';
      }
    }

    result += '''
    };
  }
''';
    return result;
  }

  ///生成toString函数
  String _toString(List<String> varNames) {
    String result = '''
  @override
  String toString() {
''';

    String temp = '    return "';
    for (int i = 0; i < varNames.length; i++) {
      temp = '$temp ${varNames[i]}:' + r"$" + "${varNames[i]} ";
    }
    temp += r'\n";';
    result += '''
    $temp
  }
''';
    return result;
  }

  ///驼峰命名转换
  String _transformName(String name) {
    String filedName;
    var ts = name.split('_');
    if (ts.length == 1) {
      filedName = ts.first;
    } else {
      filedName = ts.first;
      for (int i = 1; i < ts.length; i++) {
        filedName += '${ts[i][0].toUpperCase()}${ts[i].substring(1)}';
      }
    }
    return filedName;
  }


  _Table _processTable(Map table) {
    String name = table['name'];
    int order = table['order'] ?? 1;
    String? comment = table['comment'];
    //是否系列化为class
    bool serial;
    if (table['serial'] == null) {
      serial = true;
    } else {
      serial = table['serial'];
    }

    List<String>? contain;

    if (table['contain'] == null) {
      contain = null;
    } else {
      contain = table['contain'].toString().split(',');
    }

    List<_Row> rows = [];

    for (var row in table['rows']) {
      rows.add(_processRows(row['row']));
    }

    return _Table(name, order, rows, contain, serial,comment);
  }

  _Row _processRows(Map row) {
    String name = row['name'];
    String type = row['type'];
    List<String> constraint = row['constraint'].toString().split(' ');
    String? comment = row['comment'];
    return _Row(name, type, constraint,comment);
  }

}

class _Table {
  final String name;

  final int order;

  final List<_Row> rows;

  final List<String>? contain;

  final bool serial;

  final String? comment;

  const _Table(this.name,this.order,this.rows,this.contain,this.serial,this.comment);
}

class _Row {
  final String name;

  final String type;

  final List<String> constraint;

  final String? comment;

  const _Row(this.name,this.type,this.constraint,this.comment);

}
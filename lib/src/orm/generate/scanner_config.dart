import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:alkaid/src/orm/config/database_config.dart';

///扫描database_config.yaml文件，生成DatabaseConfig
///[path] 配置文件路径
List<DatabaseConfig> scannerConfig(String path) {
  YamlMap yamlMap = loadYaml(File(path).readAsStringSync());
  List<DatabaseConfig> list = <DatabaseConfig>[];
  for(var element in yamlMap['databases']) {
    String name = element['database']['name'];
    String host = element['database']['host'];
    int port = element['database']['port'];
    String user = element['database']['user'];
    String password = element['database']['password'];
    bool? secure = element['database']['secure'];
    String? databaseName = element['database']['databaseName'];
    String? collation = element['database']['collation'];
    DatabaseConfig databaseConfig = DatabaseConfig(name: name, host: host,
        port: port, user: user, password: password,
      secure: secure,
      databaseName: databaseName,
      collation: collation
    );
    list.add(databaseConfig);
  }
  return list;
}
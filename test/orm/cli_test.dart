import 'package:alkaid/src/orm/alkaid_orm_cli.dart';

void main() {
  // AlkaidOrmCli alkaidOrmCli = AlkaidOrmCli(
  //     yamlTemplatePath: '/home/pyoc/Documents/IdeaProject/alkaid/lib/src/orm/template/orm.yaml',
  //     configPath: '/home/pyoc/Documents/IdeaProject/alkaid/lib/src/orm/template/database_config.yaml');
  // alkaidOrmCli.init();
  String sql = "insert into class_inf values(null,?,?)";
  List<String> elements = sql.substring(sql.lastIndexOf(RegExp(r'VALUES|values'))).replaceAll(')', '').replaceAll('(', '').replaceAll(RegExp(r'VALUES|values'), '').split(',');
  print(elements);

}
import 'package:alkaid/src/orm/alkaid_orm_cli.dart';

void main() {
  AlkaidOrmCli alkaidOrmCli = AlkaidOrmCli(
      yamlTemplatePath: '/home/pyoc/Documents/IdeaProject/alkaid/lib/src/orm/template/orm.yaml',
      configPath: '/home/pyoc/Documents/IdeaProject/alkaid/lib/src/orm/template/database_config.yaml');
  alkaidOrmCli.init();
}
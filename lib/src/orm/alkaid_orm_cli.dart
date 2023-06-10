import 'dart:io';
import 'package:alkaid/src/orm/generate/add_method.dart';
import 'package:mysql_client/mysql_client.dart';
import 'generate/mapping_generation.dart';
import 'generate/yaml_to_orm.dart';
import 'package:alkaid/src/orm/generate/gpt.dart';
import 'generate/database_generation.dart';
import 'generate/scanner_config.dart';
import 'config/database_config.dart';
import 'package:io/ansi.dart';

///orm脚手架
/*
  1.提出需求，GPT编写YAML文档
  2.根据YAML文档生成Class
  3.序列化到数据库中
  4.生成抽象Mapping和实现类
  5.为抽象Mapping添加增删改查方法(GPT)
 */
class AlkaidOrmCli {
  //自动(true)按照顺序从0开始构建
  //手动(false)，自主选择
  late final bool automatic;
  late final List<DatabaseConfig> configs;
  //数据库模型模板文件
  final String yamlTemplatePath;
  late final MySQLConnection mySQLConnection;
  final GPT gpt = GPT();
  final YamlToOrm yamlToOrm = YamlToOrm();
  late  DatabaseGeneration? databaseGeneration;
  MappingGeneration? mappingGeneration ;
  late final DatabaseConfig databaseConfig;
  String configPath;
  late String _yamlPath;

  AlkaidOrmCli({required this.yamlTemplatePath,required this.configPath}) {
    _checkPackages();
  }
  
  Future<void> _loadConnection() async {
    print(yellow.wrap('正在加载配置文件...'));
    configs = scannerConfig(configPath);
    print("请选择数据库名称:");
    String name = _scannerString();
    if(configs.any((element) => element.name == name)) {
       databaseConfig = configs.firstWhere((element) => element.name == name);
      mySQLConnection = await MySQLConnection.createConnection(
          host: databaseConfig.host,
          userName: databaseConfig.user,
          password: databaseConfig.password,
          port: databaseConfig.port,
          secure: databaseConfig.secure,
          collation: databaseConfig.collation
      );
      await mySQLConnection.connect();
      print(yellow.wrap('数据库连接完成'));
      // databaseGeneration = DatabaseGeneration(mySQLConnection, databaseConfig.databaseName!);
    } else {
      print(red.wrap('没有$name配置项'));
      exit(0);
    }
  }

  void _checkPackages() {
    bool sw(String s) {
      return Platform.executableArguments.any((element) => element.startsWith(s));
    }

    if(!sw('--packages')) {
      print(red.wrap('请添加 --packages=.dart_tool/package_config.json启动标志'));
      exit(0);
    }
  }

  void init() async {
    await _loadConnection();
    print(yellow.wrap('是否重头开始构建?'));
    automatic = _scannerBool();
    if(automatic) {
      await _gptWriteYaml();
      print(blue.wrap('根据YAML文档生成Class'));
      await _yamlCompileClass(_yamlPath);
      print(blue.wrap('反序列化到数据库'));
      await _toDatabase();
      print(blue.wrap('生成mapping'));
      await _compileMapping();
      print(blue.wrap('添加抽象方法'));
      await _addMappingMethod(_yamlPath);
    } else {
      while (true) {
        print(yellow.wrap('''
  1.提出需求，GPT编写YAML文档
  2.根据YAML文档生成Class
  3.序列化到数据库中
  4.生成抽象Mapping和实现类
  5.为抽象Mapping添加增删改查方法(GPT)
  0.退出
      '''));
        print("请选择:");
        int result = _scannerInt();
        switch (result) {
          case 1:
            await _gptWriteYaml();
            break;
          case 2:
            await _yamlCompileClass(null);
            break;
          case 3:
            await _toDatabase();
            break;
          case 4:
            await _compileMapping();
            break;
          case 5:
            await _addMappingMethod(null);
            break;
          case 0:
            if(mySQLConnection.connected) {
             await mySQLConnection.close();
            }
            return;
          default:
            print(red.wrap("请重新输入"));
            break;
        }
      }
    }
  }


  // 提出需求，GPT编写YAML文档
  Future<void> _gptWriteYaml() async {
    print(yellow.wrap('请输入数据库模型文件保存的路径(保存为yaml格式):'));
    String filePath = _scannerString();
    print(yellow.wrap('请输入数据库模型描述(请输入英文):'));
    String userInput = _scannerString();
    if(automatic) {
      _yamlPath = filePath;
    }
    await gpt.yaml(userInput, filePath,yamlTemplatePath);
    while(true) {
      print("是否继续对话?");
      bool next = _scannerBool();
      if(next) {
        print(yellow.wrap('请输入:'));
        String input = _scannerString();
        await gpt.yaml(input, filePath, yamlTemplatePath);
      } else {
        return ;
      }
    }
  }

  //根据YAML文档生成Class
  Future<void> _yamlCompileClass(String? filePath) async {
    if(filePath == null) {
      print(yellow.wrap('请输入yaml文件路径:'));
       filePath = _scannerString();
    }
    print(yellow.wrap('请输入输出文件路径:'));
    String outPath = _scannerString();
    await yamlToOrm.start(filePath, outPath);
  }


  //3.序列化到数据库中
  Future<void> _toDatabase() async {
    print(yellow.wrap('初始化时是否删除${databaseConfig.name}的内容?'));
    bool t = _scannerBool();
    if(t) {
      databaseGeneration = DatabaseGeneration(mySQLConnection, databaseConfig.databaseName!,deleteDatabase: true);
    } else {
      databaseGeneration = DatabaseGeneration(mySQLConnection, databaseConfig.databaseName!,deleteDatabase: false);
    }
    print("正在扫描lib下的所有模型文件...");
    await databaseGeneration!.start();
  }

  //生成抽象Mapping和实现类
  Future<void> _compileMapping() async {
    if(mappingGeneration == null) {
      print(yellow.wrap("请输入dao文件保存的路径(实现类默认在impl/):"));
          String daoPath = _scannerString();
      mappingGeneration = MappingGeneration(daoPath);
    } else {
      print(yellow.wrap('是否继续保存在${mappingGeneration!.daoPath}?'));
      bool t = _scannerBool();
      if(!t) {
        print(yellow.wrap('请输入保存路径:'));
        mappingGeneration!.daoPath = _scannerString();
      }
    }
    print(yellow.wrap('正在生成mapping'));
    await mappingGeneration!.compileMapping();
    print(yellow.wrap('正在生成mapping实现类'));
    await mappingGeneration!.compileMappingImpl();
  }


  //为抽象Mapping添加增删改查方法(GPT)
  Future<void> _addMappingMethod(String? path) async {
    print(yellow.wrap("请输入修改的mapping文件路径:"));
    String changeFilePath = _scannerString();
    if(path == null) {
      print(yellow.wrap('请输入数据库模型文件的路径:'));
       path = _scannerString();
    }
    while(true) {
      print(yellow.wrap('请输入你的需求(exit退出):'));
      String input = _scannerString();
      if(input == 'exit') {
        return ;
      }
      var result = await gpt.method(input, path);
       addMethod(result, changeFilePath);
       print(yellow.wrap('修改完成'));
    }
  }




  bool _scannerBool() {
    while(true) {
      var input = stdin.readLineSync();
      if (input == null) {
        print(red.wrap('请重新输入'));
        continue;
      }
      input = input.trim();
      if(input == 'y' || input == 'yes') {
        return true;
      }else if(input == 'n' || input == 'no') {
        return false;
      }
    }
  }

  int _scannerInt() {
    while(true) {
      var input = stdin.readLineSync();
      if (input == null) {
        print(red.wrap('请重新输入'));
        continue;
      }
      input = input.trim();
      try {
        int result = int.parse(input);
        return result;
      } catch(e) {
        print(red.wrap('请重新输入!'));
      }
    }
  }

  String _scannerString() {
    while(true) {
      var input = stdin.readLineSync();
      if (input == null) {
        print(red.wrap('请重新输入'));
        continue;
      }
      input = input.trim();
      return input;
    }
  }
}
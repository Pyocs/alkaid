import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:io/ansi.dart';
import 'dart:convert';

///与ai交互
//[
//     {
//         "role": "system",
//         "content": "As a code generator, your task is to create a code example using TailwindCSS for a specific type of webpage. Your output should be in Markdown format. Please note that the code should not include any image elements."
//     },
//     {
//         "role": "user",
//         "content": "generate a TailwindCSS code for 灰色按钮 Webpage."
//     },
//     {
//         "role": "assistant",
//         "content": "```htm<button  class=\"bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded\">Click me</button>```"
//     },
//     {
//         "role": "user",
//         "content": "generate a TailwindCSS code for 写一个购物车 Webpage."
//     }
// ]


/*
  curl https://api.openai.com/v1/edits \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "text-davinci-edit-001",
    "input": "What day of the wek is it?",
    "instruction": "Fix the spelling mistakes"
  }'

{
  "model": "text-davinci-edit-001",
  "input": "What day of the wek is it?",
  "instruction": "Fix the spelling mistakes",
}

{
  "object": "edit",
  "created": 1589478378,
  "choices": [
    {
      "text": "What day of the week is it?",
      "index": 0,
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 32,
    "total_tokens": 57
  }
}

 */


//“作为代码生成器，你的任务是根据用户输入 为数据库模型创建yaml格式的代码。你的输出应为 Markdown 格式。请注意，代码不应包含任何图像元素。”
// "order为该数据库创建的顺序，越小越先创建"
// "你应该使用特定的约束名称,如:primary auto foreign"
// "外键约束foreign(todo_inf,id) 前者外外连接的表，后者为连接的字段名称"
// “contain表示该对象是否包含另一个对象,many表示包含多个该类型的对象,one表示只包含一个该对象”
// "serial表示该表是否会被创建为Class"
String getProxy(Uri uri) {
  return "PROXY localhost:7890";
}

///与AI交互的部分
///1.生成yaml文档
///2.生成抽象方法
class GPT {
  final String key = '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';

  final String model = 'gpt-3.5-turbo';

  final HttpClient httpClient = HttpClient()..findProxy = getProxy;

  ///是否为首次生成yaml文档
  bool _firstYaml = false;

  ///生成yaml文档
  ///[input] 用户输入生成的数据库模型描述
  ///[path] 文档保存的路径
  ///当AI生成模型后，如果是首次生成，则将assistant的内容替换成ai生成，并将聊天上下文写入缓存，在后续的聊天中一并发送给AI
  Future<void> yaml(String input,String path,String templateFilePath) async {
    final Uri uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    File temp = File("./.yaml_generation_history");
    bool t = await _proxyIsNormal();
    if(!t) {
      return ;
    }
    HttpClientRequest httpClientRequest = await httpClient.postUrl(uri);
    httpClientRequest.headers.set('Content-Type', 'application/json');
    httpClientRequest.headers.set('Authorization', 'Bearer $key');
    dynamic message;

    //如果缓存不为空，则将读取缓存
    if (temp.existsSync() && temp.lengthSync() != 0) {
      _firstYaml = false;
      print(yellow.wrap('正在读取yaml对话上下文...'));
      // message = json.encode(temp.readAsStringSync());
      message = temp.readAsStringSync();
      print(yellow.wrap('继续上次对话'));
      List<int> stack = [];
      int index = 0;
      for (int i = 0; i < message.length; i++) {
        // [
        if (message[i].codeUnits.first == 91) {
          stack.add(91);
        } else if (message[i].codeUnits.first == 93) {
          if (stack.last == 91) {
            stack.removeLast();
            if (stack.isEmpty) {
              index = i;
              break;
            }
          }
        }
      }
      message =
          message.replaceRange(index, null, ",{role:user,content:$input}]");
      message = message.toString().replaceAll('[', '').replaceAll(']', '');

      message = _parse(message);
    } else {
      print(yellow.wrap("新的对话"));
      temp.createSync();
      _firstYaml = true;
      message = <Map<String, dynamic>>[
        {
          "role": "system",
          "content": "As a code generator, your task is to create yaml-formatted code for your database model based on user input. Your output should be in Markdown format. Note that the code should not contain any image elements."
        },
        {
          "role": "assistant",
          "content": File(
              templateFilePath)
              .readAsStringSync()
        },
        {
          "role": "system",
          "content": "order is the order in which the database was created, the smaller it is, the earlier it is created You should use specific constraint names like: primary auto foreignForeign key constraint foreign(todo_inf,id) The former is the table of the outer and outer connection, and the latter is the field name of the connection"
        },
        {
          "role": "system",
          "content": "contain indicates whether the object contains another object, many indicates that it contains multiple objects of this type, and one indicates that it contains only one object serial indicates whether the table will be created as a Class"
        },
        {
          "role": "user",
          "content": input
        }
      ];
    }
    var body = {
      "model": model,
      "messages": message
    };

    //发送请求
    httpClientRequest.write(json.encode(body));
    HttpClientResponse httpClientResponse = await httpClientRequest.close();

    //写入响应
    //临时文件，读取完完整响应后会删除
    File temporaryFile = File('/tmp/${_randomName(6)}_dart');
    // IOSink ioSink = File(path).openWrite(mode: FileMode.append);
    IOSink ioSink = temporaryFile.openWrite(mode: FileMode.append);
    Completer<void> completer = Completer<void>();
    late StreamSubscription streamSubscription;
    streamSubscription = httpClientResponse.listen((response) {
      //暂停流，等待数据处理
      streamSubscription.pause();

      var part = String.fromCharCodes(response);
      ioSink.write(part);

      //恢复流，继续接受数据
      streamSubscription.resume();
      //接受完成
    }, onDone: () async {
      await ioSink.close();
      streamSubscription.cancel();
      print(yellow.wrap("读取完成"));
      completer.complete();
    });

    //等待接受完完整响应
    await completer.future;

    //处理响应
    var result = temporaryFile.readAsStringSync();

    //删除缓存文件
    temporaryFile.deleteSync();

    var object = json.decode(result);
    String? yaml;
    RegExp codeBlockPattern = RegExp(r'\`\`\`[yaml]?[\s\S]*?\`\`\`');
    Iterable codeBlockMatches = codeBlockPattern.allMatches(result);

    for (RegExpMatch math in codeBlockMatches) {
      yaml = math.group(0);
    }
    //说明AI没有使用Markdown格式，手动解析
    yaml ??= object['choices'][0]['message']['content'];

    //写入对话缓存
    if ((message as List)[1].toString().contains('assistant')) {
      message.removeAt(1);
    }
    message.add(object['choices'][0]['message']);
    temp.writeAsString(message.toString());

    print(green.wrap('AI:${object['choices'][0]['message']['content']}'));
    print(blue.wrap("保存为yaml文档(yes|y):"));

    bool scan = _inputBool();
    if (scan) {
      //将解析后的完整yaml文档写入硬盘
      var out = yaml!.replaceAll('\`\`\`', '').replaceAll('yaml', '');
      File file = File(path);
      if (file.existsSync()) {
        print(blue.wrap('文件已经存在，是否覆盖?'));
        if(_inputBool()) {
          //覆盖文件
          file.deleteSync();
          file.createSync();
        } else {
          String name = '$path${_randomName(6)}';
          file = File(name);
          print(yellow.wrap('文件已保存到:$path'));
        }
      }
      ioSink = file.openWrite(mode: FileMode.append);
      for (var line in out.split(r'\n')) {
        ioSink.writeln(line);
      }
      ioSink.close();
    }
  }


  ///生成mapping抽象方法
  ///[input] 用户输入
  ///[path] 数据库模型文件
  Future<String> method(String input,String path) async {
    final Uri uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    File temp = File("./.method_generation_history");
    //将完整响应写入temporaryFile
    File temporaryFile = File('/tmp/${_randomName(6)}_dart');
    IOSink ioSink = temporaryFile.openWrite(mode: FileMode.append);

    //数据模型文件
    File file = File(path);
    var databaseModel = file.readAsStringSync();
    dynamic message;

    //如果存在缓存，读取缓存
    if (temp.existsSync() && temp.lengthSync() != 0) {
      _firstYaml = false;
      print(yellow.wrap('正在读取method对话上下文...'));
      // message = json.encode(temp.readAsStringSync());
      message = temp.readAsStringSync();
      print(yellow.wrap('继续上次对话'));
      List<int> stack = [];
      int index = 0;
      for (int i = 0; i < message.length; i++) {
        // [
        if (message[i].codeUnits.first == 91) {
          stack.add(91);
        } else if (message[i].codeUnits.first == 93) {
          if (stack.last == 91) {
            stack.removeLast();
            if (stack.isEmpty) {
              index = i;
              break;
            }
          }
        }
      }
      message =
          message.replaceRange(index, null, ",{role:user,content:$input}]");
      message = message.toString().replaceAll('[', '').replaceAll(']', '');
      message = _parse(message);
    } else {
      //创建缓存
      print(yellow.wrap("新的对话"));
      temp.createSync();
      message = <Map<String,dynamic>>[
        {
          "role":"system",
          "content":"As a dart code generator, your task is to write abstract methods with sql statements based on existing database models and user requirements; Your answer only needs code, and the code only needs to contain abstract methods and annotations, and does not need to contain the 'import' part"
        },
        {
          "role": "system",
          "content": "There are four kinds of annotations, which are Select, Update, Delete, and Insert. Among them, the three annotations of Update, Delete, and Insert only need to contain sql statements."
        },
        {
          "role":"assistant",
          "content":"For example :@Update('update person_inf set person_age = ? where person_id = ?')\ndynamic updatePerson(Person person);"
        },
        {
          "role":"assistant",
          "content":"@Delete('delete from person_inf where person_id = ?')\n dynamic deletePerson(int id)"
        },
        {
          "role":"assistant",
          "content":"@Insert('insert into person_inf values (?,?,?))\ndynamic insertPerson(Person person);"
        },
        {
          "role":"system",
          "content":"Select annotation eliminates the need for SQL statements and Type object (deserialized object type), bool autoInject (whether it is automatically mapped according to the hump nomenclature), Map<String, String)? fields (custom mapping rules, database: class )"
        },
        {
          "role":"assistant",
          "content":"For example:@Select('select * from person_inf where person_age >= ?', Person)\nFuture<dynamic> getPersonByAge(int age);"
        },
        {
          "role":"assistant",
          "content":"@Select('select p.*, a.*,owner_id,address_id from person_inf p join person_address pa on p.person_id = pa.owner_id join address_inf a on pa.address_id = a.addr_id where p.person_id = ?' , Person)\n Future<dynamic> getPersonByAddress(int id);"
        },
        {
          "role":"assistant",
          "content":r"@Select('''SELECT person_inf.person_id, person_inf.person_name, person_inf.person_age,address_inf.addr_id,address_inf.addr_detail FROM person_inf JOIN address_inf ON address_inf.owner_id = person_inf.person_id WHERE person_inf.person_id = ?''',Person,autoInject: false,fields: {'id':'personId','name':'personName','age':'personAge','addr_id':'addrIdl',"+
              r"'addr_detail':'addrDetail }) \n Future<dynamic> getPersonById(int id);"
        },
        {
          "role":"system",
          "content":"The return of Insert Update Delete is dynamic Select return value is Future, if Select has multiple results, it should be Future<List>;The parameters passed in by the abstract function can be composite objects, such as tables defined in the database such as Person and Student"
        },
        {
          "role":"system",
          "content":"Special attention: the order of ? in the sql statement should be consistent with the formal parameter order of the function"
        },
        {
          "role":"system",
          "content":"This is the specific database model, you need to write code based on the database model, previous examples, and user needs \n$databaseModel"
        },
        {
          "role":"user",
          "content":input
        }
      ];
    }

    var body = {
     "model":model,
      "messages": message
    };

    var t = await _proxyIsNormal();
    if(!t) {
      exit(0);
    }
    //发送请求
    HttpClientRequest httpClientRequest = await httpClient.postUrl(uri);
    httpClientRequest.headers.set('Content-Type', 'application/json');
    httpClientRequest.headers.set('Authorization', 'Bearer $key');
    httpClientRequest.write(json.encode(body));
    HttpClientResponse httpClientResponse = await httpClientRequest.close();
    late StreamSubscription streamSubscription;
    Completer<void> completer = Completer<void>();
    streamSubscription = httpClientResponse.listen((response) {
      //暂停流，处理数据
      streamSubscription.pause();
      ioSink.write(String.fromCharCodes(response));
      //恢复流
      streamSubscription.resume();
    },onDone: () async {
      await ioSink.close();
      streamSubscription.cancel();
      completer.complete();
      print(yellow.wrap("接收完成"));
    });

    //等待数据接受完成
    await completer.future;

    //处理响应
    var result = temporaryFile.readAsStringSync();

    //删除缓存文件
    temporaryFile.deleteSync();

    var object = json.decode(result);
    String? yaml;
    RegExp codeBlockPattern = RegExp(r'\`\`\`[dart]?[\s\S]*?\`\`\`');
    Iterable codeBlockMatches = codeBlockPattern.allMatches(result);

    for (RegExpMatch math in codeBlockMatches) {
      yaml = math.group(0);
    }
    //说明AI没有使用Markdown格式，手动解析
    yaml ??= object['choices'][0]['message']['content'];

    //将对话信息写入缓存
    message.add(object['choices'][0]['message']);
    temp.writeAsString(message.toString());

    print(green.wrap('AI:${object['choices'][0]['message']['content']}'));
    return yaml!;
  }


  ///根据yaml文档绘画出E-R图
  ///[path] 文件路径
  void yamlToPicture(String path) async {
    final Uri uri = Uri.parse('https://api.openai.com/v1/images/generations');

    File tempFile = File('/tmp/${_randomName(6)}_dart');
    IOSink ioSink = tempFile.openWrite(mode: FileMode.append);

    HttpClientRequest httpClientRequest = await httpClient.postUrl(uri);
    httpClientRequest.headers.set('Content-Type', 'application/json');
    httpClientRequest.headers.set('Authorization', 'Bearer $key');

    File file = File(path);
    var message = file.readAsStringSync();

    var body = {
      "prompt":"A cute baby sea otter"
      // "prompt":"Draw the ER diagram according to the following database creation statement \n $message"
    };

    //发送请求
    httpClientRequest.write(json.encode(body));
    HttpClientResponse httpClientResponse = await httpClientRequest.close();
    late StreamSubscription streamSubscription;
    Completer<void> completer = Completer<void>();
    streamSubscription = httpClientResponse.listen((response) {
      //暂停流，处理数据
      streamSubscription.pause();
      ioSink.write(String.fromCharCodes(response));
      //恢复流
      streamSubscription.resume();
    },onDone: () async {
      await ioSink.close();
      streamSubscription.cancel();
      completer.complete();
      print(yellow.wrap("接受完成"));
    });

    //等待数据接受完成
    await completer.future;
    print(json.decode(json.encode(tempFile.readAsStringSync())));
    tempFile.deleteSync();
  }


  ///解析缓存中的对话上下文
  ///[message] 处理好的缓存
  List _parse(String message) {
    RegExp roleRegExp = RegExp(r'{role:\W?[\w]*?,');
    RegExp contentRegExp = RegExp(r'content:\W?[\W\w]*?}');
    List<int> stack = [];
    List list = <Map<String,dynamic>>[];
    int first = -1,second = -1;
    for(int i = 0 ; i < message.length ; i++) {
      if(message[i].codeUnits.first == 123) {
        //找到 {
        if(stack.isEmpty) {
          first = i;
        }
        stack.add(123);
      } else if(message[i].codeUnits.first == 125) {
        second = i;
        if(stack.last == 123) {
          stack.removeLast();
          if(stack.isEmpty) {
            if(first != -1 && second != -1) {
              String temp = message.substring(first,second+1);
              //处理role
              String? role = roleRegExp.allMatches(temp).first.group(0);
              assert(role!=null);
              role = role!.replaceAll('{role:', '').replaceAll(',', '');
              String? content = contentRegExp.allMatches(temp).first.group(0);
              assert(content != null);
              content = content!.replaceAll('content:', '').replaceAll('}', '');
              list.add(
                  {
                    "role":role.trim(),
                    "content":content
                  }
              );
              first = second = -1;
            }
          }
        }
      }
    }
    return list;
  }

  ///随机字符串
  ///[n] 字符串长度
  String _randomName(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(n,(_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  ///读取用户输入的是yes | no
  bool _inputBool() {
    String? scan;
    while(true) {
      scan = stdin.readLineSync();
      if(scan != null) {
        scan = scan.trim();
        if(scan == 'yes' || scan == 'y') {
          return true;
        } else if(scan == 'no' || scan == 'n') {
          return false;
        } else {
          print(red.wrap("请重新输入!"));
        }
      }
    }
  }

  Future<bool> _proxyIsNormal() async  {
    print(blue.wrap('正在检查代理...'));
    var request = await httpClient.getUrl(Uri.parse('http://ip-api.com/json'));
    var response = await request.close();
    var map =json.decode(await (response.transform(utf8.decoder).join()));
    if(map['country'] == 'Argentina') {
      print(blue.wrap('代理正常'));
      return true;
    }
    print(red.wrap('代理异常'));
    return false;
  }
}



// void main() async {
//   //person_inf表中包含Address、Customer、Employee、Manager、Person;
//   //Person中有id、name、gender、Address
//   //Address中有detail、zip、country
//   //我需要根据id查询Person的所有信息(id、name、gender、Address)
//   // GPT().yaml('This model is too simple, more complicated', '/tmp/dart/student.yaml');
//   GPT().method('Person_inf table contains Address, Customer, Employee, Manager, Person; Person has id, name, gender, Address; Address has detail, zip, country ;I need to query all information of Person (id, name, gender, Address) according to id', '/home/pyoc/Documents/IdeaProject/hello/lib/modules/orm/table.yaml');
// }
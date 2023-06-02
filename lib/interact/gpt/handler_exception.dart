import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:io/ansi.dart';

///测试时发生了异常
///1.使用modify自己修改
///2.将源代码与异常信息一同发送给AI,让AI尝试修改

final String key = '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';
final String model = 'gpt-3.5-turbo';
final HttpClient httpClient = HttpClient()..findProxy = getProxy;

String getProxy(Uri uri) {
  return "PROXY localhost:7890";
}


///使用AI修复代码中的异常
///[input] 需要处理的代码,或者用户输入内容
///[exception] 异常信息
///[tempPath]对话上写文
// result:tempPath
Future<Map<String,String?>> handlerException(String code,String? exception,String? tempPath) async {
  final Uri uri = Uri.parse('https://api.openai.com/v1/chat/completions');

  //temp 为对话上写文
   File temp;
  if(tempPath != null ) {
     temp = File(tempPath);
  } else {
    temp = File('/tmp/${_randomName(6)}_exception');
  }

  //将完整响应写入temporaryFile
  File temporaryFile = File('/tmp/${_randomName(6)}_dart');
  IOSink ioSink = temporaryFile.openWrite(mode: FileMode.append);

  dynamic message;
  if (temp.existsSync() && temp.lengthSync() != 0) {
    print(yellow.wrap('正在读取对话上下文...'));
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
        message.replaceRange(index, null, ",{role:user,content:$code}]");
    message = message.toString().replaceAll('[', '').replaceAll(']', '');

    message = _parse(message);
  } else {
    print(yellow.wrap("新的对话"));
    temp.createSync();
    message = <Map<String,dynamic>>[
      {
        "role":"system",
        "content":"As a code generator, your task is to fix exceptions in your code, and your output should be in Markdown format. Note that the code should not contain any image elements."
      },

      {
       "role":"user",
        "content":code
      },
      {
        "role":"user",
        "content":exception!
      }
    ];
  }

  var body = {
    "model":model,
    "messages": message
  };

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

  //写入对话缓存
  // if ((message as List)[1].toString().contains('assistant')) {
  //   message.removeAt(1);
  // }
  message.add(object['choices'][0]['message']);
  temp.writeAsString(message.toString());

  print(green.wrap('AI:${object['choices'][0]['message']['content']}'));
  return {
    "content":yaml,
    "path":temp.path
  };
  return {object['choices'][0]['message']['content']:temp.path};
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


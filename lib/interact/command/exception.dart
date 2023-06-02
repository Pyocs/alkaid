import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:alkaid/interact/command/scanner.dart';
import 'package:alkaid/interact/command/test.dart';
import 'package:alkaid/interact/gpt/handler_exception.dart';
import 'package:alkaid/interact/store/exception_stoer.dart';
import 'package:alkaid/interact/store/handler_store.dart';

import '../isolation/proxy_method.dart';

// handler_1:filePath
final Map<String,String> _map = HashMap();

void exception(String input) {
  input = input.trim();
  String param = input.split(' ')[1];
  if(param == 'handler') {
    int id = int.parse(input.split(' ')[2].trim());
    _handler(id);
  }
}

//需要将异常处理完或者显示退出
void _handler(int id) async {
  bool first = true;
  stdout.writeln();
  late String tempPath;
  while(true) {
    if(first) {
      print("正在使用AI处理handler->$id异常");
      print("正在读取代码和异常信息");

      String? exception = ExceptionStore.exceptionStore.get('handler', id);
      if (exception == null) {
        print('null');
        return;
      }

      String? code = HandlerStore.handlerStore.get(id);
      if (code == null) {
        print('null');
        return;
      }
      var result = await handlerException(code, exception, null);
       tempPath = result['path']!;
      String? content = result['content'];
      assert(content != null);
      first = false;

      print("是否进行测试?(将覆盖原有的异常信息)");
      bool t = scannerBoolSync();
      if (t) {
        processHandlerTest(content!, id);
      }

      print("是否保存代码到store中并退出?");
      t = scannerBoolSync();
      if (t) {
        HandlerStore.handlerStore.replace(id, content!);
      }
    } else {
      print('please input message:');
      String code = scannerNotNull();
      if(code == 'quit') {
        break;
      }
      var result = await handlerException(code, null, tempPath);

      String? content = result['content'];
      assert(content != null);
      first = false;

      print("是否进行测试?(将覆盖原有的异常信息)");
      bool t = scannerBoolSync();
      if (t) {
        processHandlerTest(content!, id);
      }

      print("是否保存代码到store中并退出?");
      t = scannerBoolSync();
      if (t) {
        HandlerStore.handlerStore.replace(id, content!);
      }
    }
  }
}





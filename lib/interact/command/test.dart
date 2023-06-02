import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:alkaid/interact/isolation/alkaid_process.dart';
import 'package:alkaid/interact/store/exception_stoer.dart';
import 'package:io/ansi.dart';
import '../isolation/proxy_method.dart';
import '../store/handler_store.dart';


Random _random = Random();
AlkaidProcess? _alkaidProcess;
List<IOSink> _ioSinks = [];
bool _throwException = false;

void test(String input) {
  _alkaidProcess ??= AlkaidProcess();
  String param = input.split(' ')[1];
  switch(param.trim()) {
    case "handler":
      _handler(input);
      break;
    case "controller":
      _controller();
      break;
    case "service":
      _service();
      break;
    case "orm":
      _orm();
      break;
    case "exit":
      _exit();
      break;
    default: throw "param error";
  }
}


//执行handler测试
//test handler all|id
void _handler(String input) async {
  input = input.trim();
  var split = input.split(' ');
  int id;
  if( split.length == 2 || input[2].trim() == 'all') {
    id = 0;
  } else {

    id = int.parse(split[2].trim());
  }

  //执行所有测试
  if(id == 0) {
    // for(var ele in HandlerStore.handlerStore.getAll()) {
    //   _processHandlerTest(ele);
    // }
    HandlerStore.handlerStore.store.forEach((key, value) {
      _processHandlerTest(value, key);
    });
  } else {
    String? input = HandlerStore.handlerStore.get(id);
    if(input == null) {
      print("not found $id");
    } else {
      _processHandlerTest(input,id);
    }
  }
}

void _controller() {

}

void _service() {

}

void _orm() {

}

//开启自动捕获异常
void startCatchException() {
  _throwException = true;
}

void stopCatchException() {
  _throwException = false;
}

void _exit() {
  for(var ele in _ioSinks) {
    ele.write('exit');
  }
  _ioSinks.clear();
}

void processHandlerTest(String input,int id,{bool cover = true}) {
  if(cover) {
    //删除原有的异常信息
    ExceptionStore.exceptionStore.remove('handler', id);
  }
  _processHandlerTest(input, id);
}


void _processHandlerTest(String input,int id) {
  bool first = true;
  File file = File('/home/pyoc/Documents/IdeaProject/alkaid/lib/interact/isolation/test');
  //将ai生成的方法添加到测试文件中
  String content = file.readAsStringSync();

  //处理方法名称
  String methodName;
  methodName = input.substring(input.indexOf('Future'),input.indexOf('(HttpRequest')).replaceAll('Future', '').trim();
  content = content.replaceAll('#replace', '$methodName(request,request.response);');
  content += '\n$input';

  String tempName = _randomString(6);
  file = File('.$tempName.dart');
  file.writeAsString(content);

  //注解中的请求方法
  String name1 = input.substring(input.indexOf('@'),input.indexOf('(')).replaceAll('@', '').trim();
  //注解中的请求路径
  String name2 = input.substring(input.indexOf(name1),input.indexOf(')')).replaceAll(name1, '').replaceAll('(', '').trim().replaceAll("'", '').trim();

  Process.start('dart', ['.$tempName.dart']).then((process) {
    process.stdout.transform(utf8.decoder).listen((event) {
      if(first) {
        int port = int.parse(event);
        addIsolateMethod(_alkaidProcess!.alkaidServer, name2, name1,
            'http://localhost:$port');
        first = false;
      }  else {
        if(event.trim() == '正在关闭') {
          print("测试已关闭...");
        }
      }
    });
    _ioSinks.add(process.stdin);
    process.stderr.transform(utf8.decoder).listen((event) {
      print(red.wrap(event));
      //发生错误直接删除缓存文件
      file.deleteSync();

      //是否捕获异常
      if(_throwException) {
        ExceptionStore.exceptionStore.add('handler',id, event);
      }
    });
  });
  print("$name1  http://localhost:3000$name2");
}


String _randomString(int n) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
      Iterable.generate(n,(_) => chars.codeUnitAt(_random.nextInt(chars.length)))
  );
}

void testClose() {
  _exit();
  _alkaidProcess?.alkaidServer.close();
}


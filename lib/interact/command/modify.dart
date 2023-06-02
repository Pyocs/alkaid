import 'dart:collection';
import 'dart:io';

import 'package:alkaid/interact/store/handler_store.dart';

// fileName : handler_1
final HashMap<String,String> _map = HashMap();
//手动修改代码
void modify(String input) {
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
    case "complete":
      _complete(input);
      break;
    default: throw "param error";
  }
}

void _handler(String input) {
  Directory directory = Directory('tmp');
  if(!directory.existsSync()) {
    directory.createSync();
  }

  if(input.split(' ').length == 2 || input.split(' ')[2].trim() == 'all' ) {
    HandlerStore.handlerStore.store.forEach((key, value) {
      String fileName;

      if(value.contains('HttpRequest')) {
        fileName = value.substring(value.indexOf('Future'),value.indexOf('(HttpRequest')).replaceAll('Future', '').trim();
      } else {
        fileName = value.substring(0,5);
      }
      _generateHandlerFile(fileName, value);
      _map.addEntries({fileName:'handler_$key'}.entries);
    });

  } else {
    int id = int.parse(input.split(' ')[2].trim());
    String? message = HandlerStore.handlerStore.get(id);
    if(message == null) {
      print(null);
      return ;
    }
    String fileName = message.substring(message.indexOf('Future'),message.indexOf('(HttpRequest')).replaceAll('Future', '').trim();
    _generateHandlerFile(fileName, message);
    _map.addEntries({fileName:'handler_$id'}.entries);
  }
}

void _controller() {

}

void _service() {

}

void _orm() {

}

void _complete(String input) {
  var split = input.trim().split(' ');
  if(split.length == 2 || split[2] == 'all') {
    //替换所有
    _map.forEach((key, value) {
      File file = File('tmp/$key.dart');
      var split = value.split('_');
      if(split[0] == 'handler') {
         HandlerStore.handlerStore.replace(int.parse(split[1]), file.readAsStringSync());
      }
    });
    _map.clear();
    print("修改完成");
  } else {
    var param = split[2].trim();
    if(param == 'handler') {
      if(split.length == 3 || split[3] == 'all') {
        //将所有handler写入
        List<String> delete = [];
        _map.forEach((key, value) {
          if(value.split('_')[0] == 'handler') {
            delete.add(key);
            //将文件写入
            int id = int.parse(value.split('_')[1]);
            HandlerStore.handlerStore.replace(id, File('tmp/$key.dart').readAsStringSync());
          }
        });
        //删除已写入的缓存
        for (var element in delete) {
          _map.remove(element);
        }
        print("修改完成");
      }  else {
        //需要保存的文件名
         String fileName = split[3];
         var result = _map[fileName];
         if(result == null) {
           print('null');
           return ;
         }

      }

    }
  }

}

void _generateHandlerFile(String fileName,String message) {
  File file = File('/home/pyoc/Documents/IdeaProject/alkaid/lib/interact/isolation/test');
  //将ai生成的方法添加到测试文件中
  String content = file.readAsStringSync();
  //处理方法名称
  String methodName;
  methodName = message.substring(message.indexOf('Future'),message.indexOf('(HttpRequest')).replaceAll('Future', '').trim();
  content = content.replaceAll('#replace', '$methodName(request,request.response);');
  content += '\n$message';

  file = File('tmp/$fileName.dart');
  file.writeAsString(content);
  print("写入完成:tmp/$fileName.dart");
}
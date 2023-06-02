import 'dart:io';

import 'package:alkaid/interact/command/scanner.dart';
import 'package:alkaid/interact/store/handler_store.dart';

void write(String input) {
  String param = input.split(' ')[1].trim();
  switch(param) {
    case "handler":
      _handler(input.split(' ')[2].trim());
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
    default: throw "param error";
  }
}

void _handler(String input) async {
  if(input == 'all') {
    print("请输入保存的文件路径名称:");
    String path = scannerNotNull();
    File file = File(path);
    var ioSink = await file.open(mode: FileMode.append);
    var list = HandlerStore.handlerStore.getAll();
    for(var ele in list) {
      ioSink.setPositionSync(file.lengthSync() +1);
      ioSink.writeStringSync('\n');
      ioSink.writeStringSync(ele);
    }
    ioSink.close();
    HandlerStore.handlerStore.removeAll();
    print("写入完成");
  } else {
    int id = int.parse(input);
    String? string = HandlerStore.handlerStore.get(id);
    if(string == null) {
      print("$id is null");
      return ;
    }

    print("请输入保存的文件路径名称:");
    String path = scannerNotNull();
    File file = File(path);
    var ioSink = await file.open(mode: FileMode.append);
    ioSink.setPositionSync(file.lengthSync() +1);
    ioSink.writeStringSync('\n');
    ioSink.writeStringSync(string);
    ioSink.close();
    HandlerStore.handlerStore.remove(id);
    print("写入完成");
  }
}

void _controller() {

}

void _service() {

}

void _orm() {

}
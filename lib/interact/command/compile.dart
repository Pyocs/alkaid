import 'package:alkaid/interact/command/scanner.dart';
import 'package:alkaid/interact/gpt/generate_handler_method.dart';
import 'package:alkaid/interact/store/handler_store.dart';

void compile(String input) {
  String param = input.split(' ')[1];
  print(param.trim());
  switch(param.trim()) {
    case "handler":
      _handler();
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

void _handler() async {
  print("please input message:");
  String input = scannerNotNull();
  String? out = await generateHandlerMethod(input);
  if(out == null) {
    print("网路错误!");
    return ;
  }
  //将结果写入store
  HandlerStore.handlerStore.add(out);
}

void _controller() {

}

void _service() {

}

void _orm() {

}
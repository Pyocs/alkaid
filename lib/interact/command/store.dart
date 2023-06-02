import 'package:alkaid/interact/command/scanner.dart';
import 'package:alkaid/interact/store/exception_stoer.dart';
import 'package:alkaid/interact/store/handler_store.dart';

// store handler get all|id
void store(String input) {
  input = input.trim();
  if(input.split(' ')[1] == 'handler') {
    _handler(input);
  } else if(input.split(' ')[1] == 'exception') {
    _exception(input);
  }
}

void _handler(String input) {
  var split = input.split(' ');
  if(split[2].trim() == 'get') {
    if(split.length == 3 || split[3].trim() == 'all') {
      HandlerStore.handlerStore.store.forEach((key, value) {
        if(value.contains('HttpRequest')) {
          print('$key  ==>  ${value.substring(value.indexOf('Future'),value.indexOf('(HttpRequest')).replaceAll('Future', '').trim()}');
        } else {
          print("$key ==> $value");
        }
      });
    } else {
      int id = int.parse(split[3].trim());
      String? value = HandlerStore.handlerStore.get(id);
      print(value);
    }
  } else if(split[2].trim() == 'remove') {

  } else if(split[2].trim() == 'add') {
    print("please input message:");
    String input = scannerText();
    HandlerStore.handlerStore.add(input);
  } else {
    throw 'param error';
  }
}

//store exception get handler all|id
void _exception(String input) {
  var split = input.split(' ');
  if(split[2].trim() == 'get') {
    if(split[3].trim() == 'handler') {
      if(split.length == 4 || split[4] == 'all') {
        //获取handler所有异常
        ExceptionStore.exceptionStore.getHandler().forEach((key, value) {
          print("$key  ==>  $value");
          print("===============================================================");
        });
      } else {
        //根据id获取handler异常
        int id = int.parse(split[4]);
        String? exception = ExceptionStore.exceptionStore.get('handler', id);
        print(exception);
      }
    }
  }
}

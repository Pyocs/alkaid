import 'dart:async';
import 'dart:convert';
import 'dart:io';

String scannerNotNull() {
  while(true) {
    String? input = stdin.readLineSync();
    if(input == null) {
      print("请重新输入");
    } else {
      return input;
    }
  }
}

//读取一段文本，以quit结尾
String scannerText() {
  StringBuffer stringBuffer = StringBuffer();
  while(true) {
    String? input = stdin.readLineSync();
    if(input != null && input.trim() == 'quit') {
      return stringBuffer.toString();
    }
    stringBuffer.writeln(input);
  }
}

bool scannerBoolSync() {
  while(true) {
    String? input = stdin.readLineSync();
    if(input != null &&( input.trim() == 'yes' || input.trim() == 'y')) {
      return true;
    }  else if( input != null && (input.trim() == 'n' || input.trim() == 'no')) {
      return false;
    }
    print("请重新输入:");
  }
}

Future<bool> scannerBool() {
  Completer<bool> completer = Completer();
  late StreamSubscription streamSubscription;
  streamSubscription = stdin.listen((event) {
    String input = String.fromCharCodes(event).trim();
    if(input == 'n' || input == 'no') {
      completer.complete(false);
      streamSubscription.cancel();
    } else if(input == 'y' || input == 'yes') {
      completer.complete(true);
      streamSubscription.cancel();
    }
  });
  return completer.future;
}


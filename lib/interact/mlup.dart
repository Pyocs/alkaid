///自然语言编程
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:alkaid/interact/command/compile.dart';
import 'package:alkaid/interact/command/exception.dart';
import 'package:alkaid/interact/command/modify.dart';
import 'package:alkaid/interact/command/store.dart';
import 'package:alkaid/interact/command/test.dart';
import 'package:alkaid/interact/command/write.dart';

///分为四个功能
///1.编写处理方法
///2.编写控制器
///3.编写服务
///4.编写ORM
void main() async {
  /*
    input: compile handler
           compile controller
           compile service
           compile orm

    input: test handler all|id
           test controller
           test service
           test orm

    input: write handler all|id
           write controller
           write service
           write orm


    input: store handler get all|id
           store remove

    input: modify handler all| filename

    input: exception handler id

   */
  late StreamSubscription streamSubscription;
  streamSubscription = stdin.transform(utf8.decoder).listen((input) {
      if(input.startsWith('compile')) {
        compile(input);
      } else if(input.startsWith('test')) {
        test(input);
      } else if(input.startsWith('store')) {
        store(input);
      } else if(input.startsWith('exit')) {
        print("正在关闭");
        testClose();
        streamSubscription.cancel();
        return ;
      } else if(input.startsWith('write')) {
        write(input);
      } else if(input.startsWith('modify')) {
        modify(input);
      } else if(input.startsWith('exception')) {
        exception(input);
      }
        else if(input.trim() == 'start catch') {
        startCatchException();
        print("开启成功");
      } else if(input.trim() == 'stop catch') {
        stopCatchException();
        print("关闭成功");
      }
  });
}
import 'dart:isolate';
import 'package:alkaid/src/core/isolate_pool.dart';
import 'package:io/ansi.dart';

int i = 1;

void main() async {
  ReceivePort receivePort = ReceivePort();
  Isolate isolate = await Isolate.spawn(test,receivePort.sendPort);
  print(i);
  await Future.delayed(Duration(seconds: 1));
  print(i);
}

void test(SendPort sendPort ) {
  i++;
  print(yellow.wrap(i.toString()));
  print('进程正在执行');
}
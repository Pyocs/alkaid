import 'dart:io';
import '../../alkaid.dart';

///向事件总线写入异常并终止模块链循环

AlkaidStatus terminateLoop(AlkaidHttpException alkaidHttpException,HttpRequest request) {
  AlkaidServer.getServer().modulesCollection.add(HttpContextMeta(request, alkaidHttpException));
  return AlkaidStatus.stop;
}
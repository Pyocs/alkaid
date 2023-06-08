import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:alkaid/src/core/isolate_pool.dart';
import 'package:alkaid/src/status/isolate_status.dart';
typedef IsolateHandler = FutureOr<dynamic> Function(dynamic);
///代表一个Isolate任务，该Isolate中可同时执行多个task
class IsolateMeta {
  final String name;
  late final Isolate isolate;
  ReceivePort receivePort;
  SendPort sendPort;
  FutureOr<dynamic> Function(dynamic) task;
  IsolateStatus status;
  late Stream stream;
  bool keepConnection;
  bool kill = false;
  IsolateMeta(this.name,this.receivePort,this.sendPort,this.task,this.status,this.keepConnection);


  Future<void> initSendPort() async {
    //恢复Isolate
    if(status == IsolateStatus.unInit) {
      isolate.resume(isolate.pauseCapability!);
      status = IsolateStatus.running;
      stream = receivePort.asBroadcastStream();
      sendPort = await  stream.first;
      if(keepConnection) {
        sendPort.send(IsolateStatus.survive);
      }
      listen();
    }
  }

  void listen() {
     stream.listen((message) {
      if(message is IsolateStatus) {
        status = message;
        if(status == IsolateStatus.stop || status == IsolateStatus.finish) {
          //将资源归还池
          IsolatePool.dispose(this);
          if(kill) {
            isolate.kill();
            receivePort.close();
          }
        }
      }
    });
  }


  Future<dynamic> send(dynamic message) async {
    if(status == IsolateStatus.stop) {
      isolate.resume(isolate.pauseCapability!);
      status = IsolateStatus.running;
    }

    sendPort
      ..send(message)
      ..send(task);
    Completer completer = Completer();
    stream.first.then(completer.complete);
    return completer.future;
  }
}
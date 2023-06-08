import 'dart:async';
import 'dart:isolate';
import 'package:alkaid/src/status/isolate_status.dart';

void internalTask(SendPort sendPort) async {
  Isolate isolate = Isolate.current;
  ReceivePort receivePort = ReceivePort();
  //传递参数
  dynamic param;
  bool hasSurvive = false;

  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    if (message is Function) {
      Completer<dynamic> completer = Completer();
      var result = message.call(param);
      if(result is Future) {
        result.then((value) => completer.complete(value));
      } else {
        completer.complete(result);
      }
      //完成task后检查等待队列中是否还有任务，如果没有任务执行，则pause该Isolate
      completer.future.then((value) {
          sendPort.send(value);
          if(!hasSurvive) {
            sendPort.send(IsolateStatus.stop);
            isolate.pause(isolate.pauseCapability);
          } else {
            sendPort.send(IsolateStatus.finish);
          }
      });
    } else if(message == IsolateStatus.survive) {
      hasSurvive = true;
    } else {
      param = message;
    }
  });
}


void internalOnceTask(SendPort sendPort) {
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  late StreamSubscription streamSubscription;
  dynamic param;


  streamSubscription = receivePort.listen((message) {
    if(message is Function) {
      var result = message.call(param);
      if(result is Future) {
        result.then((value) {
          sendPort.send(value);
          streamSubscription.cancel();
          Isolate.current.kill();
        });
      } else {
        sendPort.send(result);
        streamSubscription.cancel();
        Isolate.current.kill();
      }
    } else {
      param = message;
    }
  });

}
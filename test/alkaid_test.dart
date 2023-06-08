import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
bool pause = false;
void main() async {
  ReceivePort receivePort = ReceivePort();
  //暂停isolate
  Isolate isolate = await Isolate.spawn(_internalTask,receivePort.sendPort,paused: true);
  isolate.resume(isolate.pauseCapability!);
  receivePort.listen((message) async {
    if(message is SendPort) {
      message.send(1000);
      message.send(demo);
      await Future.delayed(Duration(seconds: 1));
      print(pause);
      if(!pause) {
        // isolate.resume(isolate.pauseCapability!);
        pause = false;
        message.send(2000);
        message.send(demo);
      }
    } else {
      print(message);
    }
  });
}

Future<void> _internalTask(SendPort sendPort) async {
  final Queue<Completer> waitQueue = Queue();
  Isolate isolate = Isolate.current;
  ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  dynamic param;
  receivePort.listen((message) async {
    if(message is Function) {
      Completer<dynamic> completer = Completer();
      var result = message.call(param);
      waitQueue.addFirst(completer);
      completer.complete(result);
      completer.future.then((value) {
        waitQueue.remove(completer);
        sendPort.send(value);
        if(waitQueue.isEmpty) {
          isolate.pause(isolate.pauseCapability);
          print('isolate is pause');
          pause = true;
        }
      });
    } else {
      param = message;
    }
  });


}

int demo(int n) {
  int result = 0;
  for(int i = 0 ; i < n ; i++) {
    result += i;
  }
  return result;
}

(String,int) test() {
  return ('a',1);
}
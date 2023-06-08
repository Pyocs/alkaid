import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/core/isolate_body.dart';
import 'package:alkaid/src/core/isolate_meta.dart';
import '../status/isolate_status.dart';

///线程池
class IsolatePool {
  static  IsolatePool? _isolatePool;
  //可用的线程
  //插入到最后，从头部取出
  final Map<String, Queue<IsolateMeta>> _pool = {};
  //忙碌中的线程
  final Map<String, List<IsolateMeta>> _busyPool = {};
  final Queue<(String,dynamic,Completer)> _waitQueue = Queue();
  final int minCapacity;
  final int maxCapacity;

  IsolatePool._(this.minCapacity, this.maxCapacity);

  factory IsolatePool.getPool(int minCapacity,int maxCapacity) {
    if(_isolatePool != null) {
      return _isolatePool!;
    }
    _isolatePool = IsolatePool._(minCapacity,maxCapacity);
    return _isolatePool!;
  }

  static dispose(IsolateMeta isolateMeta) {
    if (_isolatePool == null) {
      throw AlkaidServerException('isolate pool not instantiate');
    }
    if (_isolatePool!._busyPool[isolateMeta.name] != null
        && _isolatePool!._busyPool[isolateMeta.name]!.remove(isolateMeta)) {
      _isolatePool!._pool[isolateMeta.name]!.addLast(isolateMeta);

      if (_isolatePool!._waitQueue.isNotEmpty) {
        for (int i = _isolatePool!._waitQueue.length - 1; i >= 0 ; i--) {
          if (_isolatePool!
              ._waitQueue
              .elementAt(i)
              .$1 == isolateMeta.name) {
            var member = _isolatePool!._waitQueue.elementAt(i);
            _isolatePool!._waitQueue.remove(member);
            _isolatePool!._pool[member.$1]!.remove(isolateMeta);
            _isolatePool!._busyPool[member.$1]!.add(isolateMeta);
            isolateMeta.send(member.$2).then(member.$3.complete);
            break;
          }
        }
      }
    }
  }

  ///向线程池提交一个没有参数有返回值的任务，该任务只执行一次并且立即执行
  Future<dynamic> submitNotParamOnce(FutureOr<dynamic> Function() task) {
    return Isolate.run(task);
  }


  Future<void> submitRepeatTask(FutureOr<dynamic> Function(dynamic) task, String name, {
        int? minCapacity,
        int? maxCapacity,
        bool keepConnection = false
      }) async {
    minCapacity ??= this.minCapacity;
    _pool[name] ??= Queue<IsolateMeta>();
    for (int i = 0; i < minCapacity; i++) {
      ReceivePort receivePort = ReceivePort();
      IsolateMeta isolateMeta = IsolateMeta(
        name,receivePort,receivePort.sendPort,task,IsolateStatus.unInit,keepConnection
      );
      isolateMeta.isolate = await Isolate.spawn(internalTask,receivePort.sendPort,paused: true);
      _pool[name]!.addLast(isolateMeta);
    }
  }


  Future<dynamic> runTask(String name,dynamic message) async {
    if(_pool[name] == null) {
      throw AlkaidServerException('$name task not found');
    }

    if(_pool[name]!.isNotEmpty && _pool[name]!.length != 1) {
      IsolateMeta isolateMeta = _pool[name]!.removeFirst();
      _busyPool[name] ??= [];
      _busyPool[name]!.add(isolateMeta);
      if(isolateMeta.status == IsolateStatus.unInit) {
        await isolateMeta.initSendPort();
      }
      return  isolateMeta.send(message);
    }
    int capacity = _busyPool[name] == null ? 0 : _busyPool[name]!.length;
    if(capacity + 1 < maxCapacity) {
      //创建一个新的isolate
      ReceivePort receivePort = ReceivePort();
      IsolateMeta last = _pool[name]!.first;
      IsolateMeta isolateMeta = IsolateMeta(
        last.name,receivePort,receivePort.sendPort,last.task,IsolateStatus.unInit,last.keepConnection
      );
      _busyPool[name] ??= [];
      /*
        isolateMeta.isolate = await Isolate.spawn(internalTask,receivePort.sendPort,paused: true);
        由于Isolate.spawn返回的是一个Future,如果调用runTask没有使用await,则会跳过下面的函数返回，导致capacity没有发生改变
        如果其他线程也正好执行到了这里，得到的capacity会出现幻读
        所以需要将_busyPool的length长度先改变，在执行Isolate.spawn,这样即使函数返回，capacity也改变了，
        而不会出现并发资源发生错误的情况
       */
      _busyPool[name]!.add(isolateMeta);
      isolateMeta.isolate = await Isolate.spawn(internalTask,receivePort.sendPort,paused: true);
      await isolateMeta.initSendPort();
      return  isolateMeta.send(message);
    } else if(capacity +1 == maxCapacity) {
      //使用最后一个isolate
      IsolateMeta last = _pool[name]!.removeFirst();
      _busyPool[name] ??= [];
      _busyPool[name]!.add(last);
      if(last.status == IsolateStatus.unInit) {
        await last.initSendPort();
      }
      return  last.send(message);
    } else {
      //加入等待队列
      Completer completer = Completer();
      _waitQueue.addFirst((name,message,completer));
      return completer.future;
    }
  }


  Future<dynamic> runOnceTask(IsolateHandler handler,dynamic message) async {
    ReceivePort receivePort = ReceivePort();
    Isolate.spawn(internalOnceTask,receivePort.sendPort);
    Stream stream = receivePort.asBroadcastStream();
    SendPort sendPort = await stream.first;
    sendPort.send(message);
    sendPort.send(handler);
    Completer completer = Completer();
    stream.first.then((value) {
      receivePort.close();
      completer.complete(value);
    });
    return completer.future;
  }

  void clear(String name) {
    if(_pool[name] == null) {
      return ;
    }

    _waitQueue.removeWhere((element) => element.$1 == name);

    if(_busyPool[name] != null && _busyPool[name]!.isNotEmpty) {
      for (var element in _busyPool[name]!) {
        element.kill = true;
      }
    }

    for(var ele in _pool[name]!) {
      ele.isolate.kill();
      ele.receivePort.close();
    }
    _pool[name]!.clear();
    _busyPool[name]!.clear();
  }

  void close() {
    for (var element in _pool.keys) {
      clear(element);
    }
  }

}
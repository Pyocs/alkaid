import 'dart:async';
import 'dart:io';
import 'dart:collection';
import '../exception/alkaid_exception.dart';
import 'http_context_meta.dart';

///事件总线，用于存储HttpRequest的上下文信息
class ModulesCollection {
  final _HttpContext _httpContext = _HttpContext();
  final StreamController _controller = StreamController.broadcast();
  //监听的请求列表
  final Map<HttpRequest,Completer> _listenMap = HashMap();

  int get length => _httpContext.context.length;

  void add(HttpContextMeta httpContextMeta) {
    _controller.add(null);
    _httpContext.add(httpContextMeta.request, httpContextMeta.value);
    if(_listenMap.keys.contains(httpContextMeta.request)) {
      _listenMap[httpContextMeta.request]!.complete();
    }
  }

  void addAll(List<HttpContextMeta> list) {
    _controller.add(null);
    Map<HttpRequest,dynamic> map = {};
    for (var element in list) {
      map.addEntries({element.request:element.value}.entries);
      if(_listenMap.keys.contains(element.request)) {
        _listenMap[element.request]!.complete();
      }
    }
    _httpContext.addAll(map);
  }

  void repeat(HttpRequest request,dynamic value) {
    _controller.add(null);
    if(value is AlkaidException) {
      _httpContext.repeatException(request, value);
    } else {
      _httpContext.repeatValue(request, value);
    }
    if(_listenMap.keys.contains(request)) {
      _listenMap[request]!.complete();
    }
  }

  bool isException(HttpRequest request) => _httpContext.isException(request);

  dynamic get(HttpRequest request) => _httpContext.get(request);

  // Future<dynamic> getFuture(HttpRequest request,Duration timeout) async {
  //   Completer<dynamic> completer = Completer<dynamic>();
  //   Future.delayed(timeout,() {
  //     completer.complete(get(request));
  //   });
  //
  //   return completer.future;
  // }

  bool hasValues(HttpRequest request) => _httpContext.hasValue(request);

  void close() => _controller.close();

  StreamSubscription listen(void Function(dynamic value)? onData ,{Function? onError}) => _controller.stream.listen(onData,onError: onError);

  //对事件总线中的某个请求进行监听，如果该请求的值发生改变则返回新的值
  //如果timeout內没有改变则返回null
  Future listenRequest(HttpRequest request,Duration timeout) {
    if(!_listenMap.keys.contains(request)) {
      _listenMap[request] = Completer();
    }
    //监听值是否发生改变
    Completer<dynamic> completer = Completer<dynamic>();

    Timer timer = Timer(timeout, () {
      _listenMap.remove(request);
      return completer.complete(null);
    });

    _listenMap[request]!.future.then((value) {
        timer.cancel();
        completer.complete(get(request));
    });

    return completer.future;
  }

  void remove(HttpRequest request) {
    _httpContext.context.remove(request);
    if(_listenMap.keys.contains(request)) {
      _listenMap[request]!.complete();
    }
  }

  void removeAll() {
    _httpContext.context.clear();
    _listenMap.clear();
  }
}



class _HttpContext {
  final HashMap<HttpRequest,dynamic> _context = HashMap.identity();
  HashMap<HttpRequest,dynamic> get  context => _context;
  ///添加一个请求数据
  ///如果该请求已在事件总线中，则替换
  void add(HttpRequest request,dynamic value) => _context[request] = value;

  ///添加所有
  void addAll(Map<HttpRequest,dynamic> map) => _context.addAll(map);

  ///替换请求的异常，如果存在
  void repeatException(HttpRequest httpRequest,AlkaidException alkaidException ) {
    if(_context.containsKey(httpRequest)) {
      if(_context[httpRequest] is AlkaidException) {
        _context[httpRequest] = alkaidException;
      }
    }
  }

  ///替换值，不能替换异常
  void repeatValue(HttpRequest httpRequest,dynamic value) {
    if(_context.containsKey(httpRequest)) {
      if(_context[httpRequest] is! AlkaidException) {
        _context[httpRequest] = value;
      }
    }
  }

  ///判断值是否为异常
  bool isException(HttpRequest httpRequest) {
    if(_context.containsKey(httpRequest) && _context[httpRequest].runtimeType ==  AlkaidException) {
      return true;
    } else {
      return false;
    }
  }

  ///获取值
  dynamic get(HttpRequest request) => _context[request];

  ///判读是否包含值
  bool hasValue(HttpRequest request) => _context.containsKey(request);

}
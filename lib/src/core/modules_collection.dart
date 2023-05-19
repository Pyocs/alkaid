import 'dart:async';
import 'dart:io';
import 'dart:collection';

import '../exception/alkaid_exception.dart';


///事件总线，用于存储HttpRequest的上下文信息

class ModulesCollection {
  final _HttpContext _httpContext = _HttpContext();

  final StreamController _controller = StreamController.broadcast();


  void add(HttpContextMeta httpContextMeta) {
    _controller.add(null);
    _httpContext.add(httpContextMeta.request, httpContextMeta.value);
  }

  void addAll(List<HttpContextMeta> list) {
    _controller.add(null);
    Map<HttpRequest,dynamic> map = {};
    for (var element in list) {
      map.addEntries({element.request:element.value}.entries);
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
  }

  bool isException(HttpRequest request) => _httpContext.isException(request);

  dynamic get(HttpRequest request) => _httpContext.get(request);

  Future<dynamic> getFuture(HttpRequest request,Duration timeout) async {
    dynamic result;
    var start = DateTime.now();
    while((DateTime.now().difference(start)).inMicroseconds < timeout.inMicroseconds) {
      result = _httpContext.get(request);
      if(result != null) {
        return result;
      }
    }
    return result;
  }

  bool hasValues(HttpRequest request) => _httpContext.hasValue(request);

  void close() => _controller.close();

  StreamSubscription listen(void Function(dynamic value)? onData ,{Function? onError}) => _controller.stream.listen(onData,onError: onError);

}

class HttpContextMeta {
  final HttpRequest _httpRequest;
  dynamic value;

  HttpRequest get request => _httpRequest;

  HttpContextMeta(this._httpRequest,this.value);
}

class _HttpContext {
  final HashMap<HttpRequest,dynamic> _context = HashMap.identity();

  ///添加一个请求数据
  ///如果该请求已在事件总线中，则抛出异常
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
    if(_context.containsKey(httpRequest) && _context[httpRequest] is AlkaidException) {
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
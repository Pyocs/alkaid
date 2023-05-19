import 'dart:io';

import '../../exception/alkaid_server_exception.dart';

typedef HandlerRequest = Future Function(HttpRequest request,HttpResponse response);

const requestMethod = <String>['get','GET','post','POST','put','PUT','delete','DELETE',
  'patch','PATCH','copy','COPY','head','HEAD','options','OPTIONS'];

///封装了请求方法和处理方法
class RouterMeta {
  ///请求方法
  String _method;

  ///处理方法
  HandlerRequest handlerRequest;

  String get method => _method;

  set method(String method) {
    //检查方法是否正确
    if(!requestMethod.contains(method)) {
      throw AlkaidServerException.requestMethodError();
    }
    _method = method;
  }

  RouterMeta(this._method,this.handlerRequest) {
    if(!requestMethod.contains(_method)) {
      throw AlkaidServerException.requestMethodError();
    }
  }

  @override
  String toString() {
    return '${method.toUpperCase()} => $handlerRequest';
  }
}
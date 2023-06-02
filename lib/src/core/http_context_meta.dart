import 'dart:io';
///HTTP上下文
class HttpContextMeta {
  final HttpRequest _httpRequest;
  dynamic value;

  HttpRequest get request => _httpRequest;

  HttpContextMeta(this._httpRequest,this.value);
}
import 'dart:io';

class LFUCacheMetaValue {
  late final int status;
  final Map<String,dynamic> headers = {};
  dynamic body;

  LFUCacheMetaValue(HttpResponse response,{Object? object}) {
    response.headers.forEach((name, values) {
      headers[name] = values;
    });
    status = response.statusCode;
    body = object;
  }

  void setBody(Object? object) {
    body = object;
  }
}
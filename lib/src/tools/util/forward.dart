import 'dart:async';
import 'dart:io';
/*
  重定向（Redirect）:(response.redirect())
  重定向是HTTP协议的一部分，当客户端（通常是浏览器）向服务器发送请求时，
  服务器可以返回一个特殊的响应，告诉客户端去其他地方查找请求的资源。这会导致客户端向新的URL发起新的请求。
  在HTTP响应中，这通常由状态码3xx和一个Location头表示。重定向是两个完全独立的请求/响应周期。

  转发（Forward）:
  转发通常是服务器端的概念，特别是在像Servlet这样的服务器端技术中。
  当服务器收到一个请求时，它可以决定不自己处理这个请求，
  而是将请求内部转发给另一个处理器（例如，另一个Servlet）。对于客户端来说，
  它并不知道发生了转发，它只知道它发送了一个请求并收到了一个响应。转发通常在同一请求/响应周期内完成。
 */
///请求转发
///通过HttpClient重新发送请求
final HttpClient httpClient = HttpClient();
void forward(HttpRequest request,HttpResponse response,String uri,String method,{bool close = true}) async {
  if(!uri.startsWith('/')) {
    uri = '/$uri';
  }
  Completer completer = Completer<void>();
  Uri host = Uri.parse('${request.requestedUri.scheme}://${request.requestedUri.authority}$uri');
  HttpClientRequest httpClientRequest = await httpClient.openUrl(method, host);
  httpClientRequest.headers.clear();
  request.headers.forEach((name, values) {
    httpClientRequest.headers.set(name, values);
  });
  late Future<HttpClientResponse> httpClientResponse;
  request.listen((event) {
    httpClientRequest.add(event);
  },onDone: (){
    httpClientResponse =  httpClientRequest.close();
    completer.complete();
  });

  await completer.future;

  httpClientResponse.then((httpClientResponse) {
    response.headers.clear();
    httpClientResponse.headers.forEach((name, values) {
      response.headers.set(name, values);
    });
    httpClientResponse.listen((event) {
      response.add(event);
    },onDone: (){
      if(close) {
        response.close();
      }
    });
  });


}
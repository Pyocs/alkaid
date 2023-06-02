import 'dart:async';
import 'dart:io';
import '../../../alkaid.dart';


///处理websocket协议
/*
sec-websocket-extensions: permessage-deflate; client_max_window_bits
 connection: Upgrade
 sec-websocket-key: JBkzBLkKsFyPrV8WNEmlWA==
 upgrade: websocket
 sec-websocket-version: 13
 host: localhost:3306
 */
class WebSocketHttpModule extends HttpModules {

  final StreamController<WebSocket> _controller = StreamController.broadcast();

  Stream<WebSocket> get stream => _controller.stream;

  WebSocketHttpModule(String name,{int? weight = 5}) : super(name,weight: weight);

  @override
  Future check(HttpRequest request, HttpResponse response) async {
    if(WebSocketTransformer.isUpgradeRequest(request)) {
      return WebSocketTransformer.upgrade(request);
    } else if(request is WebSocket) {
      return request;
    }
    return Future.value();
  }

  @override
  Future finish(HttpRequest request, HttpResponse response) {
    // TODO: implement finish
    throw UnimplementedError();
  }

  @override
  Future handler(HttpRequest request, HttpResponse response) async {
    WebSocket? websocket = await check(request, response);
    if(websocket == null) {
      return AlkaidStatus.fail;
    } else {
      _controller.add(websocket);
      return AlkaidStatus.finish;
    }
  }

  @override
  Future later(HttpRequest request, HttpResponse response) {
    // TODO: implement later
    throw UnimplementedError();
  }

}
import 'dart:io';
import 'package:alkaid/alkaid.dart';

///测试模块
class TestHttpModule extends HttpModules {
  TestHttpModule._(String name,int weight):super(name,weight: weight);

  factory TestHttpModule.test() {
    TestHttpModule testHttpModule = TestHttpModule._('test', 1);
    AlkaidServer.getServer().httpModuleChain.addFirst(testHttpModule);
    return testHttpModule;
  }

  @override
  check(HttpRequest request, HttpResponse response) {
    throw UnimplementedError();
  }

  @override
  finish(HttpRequest request, HttpResponse response) {
    throw UnimplementedError();
  }

  @override
  handler(HttpRequest request, HttpResponse response) {
    print('\n');
    request.headers.forEach((name, values) {
      print('$name ==>  $values');
    });
    return Future.value(AlkaidStatus.fail);
  }

  @override
  Future later(HttpRequest request, HttpResponse response) {
    throw UnimplementedError();
  }

}
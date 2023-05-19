import 'dart:async';
import 'dart:collection';
import 'dart:io';

import '../../core/modules_collection.dart';
import '../../status/alkaid_status.dart';
import '../http_module.dart';


class CacheHttpModule extends HttpModules {


  ///cache的实现方式，提供两种：Map,Redis
  Map cache = HashMap();

  CacheHttpModule(String name,{int? weight}) : super(name,weight: weight);


  void setCollection(ModulesCollection modulesCollection) {
    this.modulesCollection =  modulesCollection;
  }
  ///生成key
  ///method + path
  ///ip + method + path
  String generateKey(HttpRequest request) {
    return '${request.method}${request.uri.path}';
  }



  @override
  Future handler(HttpRequest request,HttpResponse response) async {
    var value = cache[generateKey(request)];
    if(value != null) {
      response.write(value);
      response.close();
      return AlkaidStatus.finish;
    } else {
      return AlkaidStatus.wait;
    }
  }

  @override
  Future finish(HttpRequest request,HttpResponse response) async {
    throw UnimplementedError();
  }


  ///稍后有模块链调用
  @override
  Future later(HttpRequest request, HttpResponse response) async {
    var t = modulesCollection.listen((value) {
      cache[generateKey(request)] = modulesCollection.get(request);
    });

    Timer(Duration(milliseconds: 10),() {
      t.cancel();
    });
  }

  @override
  Future check(HttpRequest request, HttpResponse response) {
    // TODO: implement check
    throw UnimplementedError();
  }
}
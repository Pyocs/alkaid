import 'dart:async';
import 'dart:io';
import 'package:alkaid/src/modules/cache/LFU_cache_meta_key.dart';
import 'package:alkaid/src/modules/cache/LFU_cache_meta_value.dart';

import '../../core/modules_collection.dart';
import '../../status/alkaid_status.dart';
import '../http_module.dart';
import 'algorithm/cache_algorithm.dart';

class CacheHttpModule extends HttpModules {
  late final CacheAlgorithm _cacheAlgorithm;

  CacheHttpModule(String name,this._cacheAlgorithm,{int? weight}) : super(name,weight: weight);


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
  Future check(HttpRequest request, HttpResponse response) {
    throw Exception();
  }

  @override
  Future handler(HttpRequest request,HttpResponse response) async {
    var cache = _cacheAlgorithm.get(LFUCacheMetaKey(request));
    if(cache == null) {
      return AlkaidStatus.fail;
    }
    cache as LFUCacheMetaValue;
    response.statusCode = cache.status;
    cache.headers.forEach((key, value) {
      response.headers.set(key, value);
    });
    response.write(cache.body);
    response.close();
    return AlkaidStatus.finish;
  }

  @override
  Future finish(HttpRequest request,HttpResponse response) async {
    throw UnimplementedError();
  }


  ///稍后有模块链调用
  @override
  Future later(HttpRequest request, HttpResponse response) async {
    //将响应头、响应体提取出来写入缓存
    _cacheAlgorithm.add(LFUCacheMetaKey(request), LFUCacheMetaValue(response));
  }

  void cache(HttpRequest request,HttpResponse response,{Object? object}) {
    _cacheAlgorithm.add(LFUCacheMetaKey(request), LFUCacheMetaValue(response,object: object));
  }



}
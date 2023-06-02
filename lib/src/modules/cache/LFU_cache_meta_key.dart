import 'dart:io';
import 'algorithm/LFU_cache_algorithm.dart';
//使用请求路径加请求方法作为key
class LFUCacheMetaKey extends LFUCacheMeta<String> {
  LFUCacheMetaKey(HttpRequest request)
    :super(1, '${request.requestedUri.origin}${request.requestedUri.path}${request.requestedUri.queryParameters}${request.method}');


  @override
  bool operator ==(Object other) {
    if(other is! LFUCacheMeta) {
      return false;
    }
    return (other as LFUCacheMetaKey).key == key;
  }

  @override
  int get hashCode => key.hashCode;

}
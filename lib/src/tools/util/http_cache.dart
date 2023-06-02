import 'dart:io';
import 'package:alkaid/src/status/cache_control.dart';

///向响应Header添加HTTP缓存
void httpCache(HttpResponse response,CacheControl cacheControl,int maxAge,
  {int? length,String? eTag,DateTime? lastModified}) {
  //max-age有更高的优先级，可以忽略expires
  response.headers
      // ..add('Cache-Control', cacheControl.name)
      ..add('Last-Modified', lastModified ?? DateTime.now())
      ..expires = DateTime.now().add(Duration(seconds: maxAge));
  if(length != null) {
    response.headers.contentLength = length;
  }
  if(eTag != null) {
    response.headers.add('ETag', eTag);
  }

}
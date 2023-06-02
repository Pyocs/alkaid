import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/modules/cache/LFU_cache_meta_key.dart';
import 'package:alkaid/src/modules/cache/algorithm/LFU_cache_algorithm.dart';
import 'package:alkaid/src/modules/cache/store/sort_map_cache_store.dart';
import 'package:alkaid/src/modules/test/test_http_module.dart';
import 'package:file/local.dart';

void main()  async{
  AlkaidServer alkaidServer = await AlkaidServer.server('localhost', 3000,inject: false);
  alkaidServer.start();
  alkaidServer.routerHttpModule.get('/test', (request, response) {
    alkaidServer.modulesCollection.add(HttpContextMeta(request, 'Hello world'));
    return AlkaidStatus.fail;
  });

  RouterHttpModule routerHttpModule = RouterHttpModule('router_test',weight: 9);

  //如果请求方法返回Null,那么模块链会提前结束循环
  routerHttpModule.get('/test', (request, response) {
    response.write(alkaidServer.modulesCollection.get(request));
  });

  alkaidServer.crossHttpModule.addWhiteRule('/auth');

  CacheHttpModule cacheHttpModule = CacheHttpModule('cache',
      LFUCacheAlgorithm(SortMapCacheStore(
          (a,b) {
            return (a as LFUCacheMetaKey).widget - (b as LFUCacheMetaKey).widget;
          }
      ),
          10),weight: 1);

  alkaidServer.httpModuleChain.add(cacheHttpModule);

  alkaidServer.routerHttpModule.get('/time', (request, response)  {
    DateTime dateTime = DateTime.now();
    response.write(dateTime);
    cacheHttpModule.cache(request, response,object: dateTime);
  });

  StaticHttpModule staticHttpModule = StaticHttpModule(LocalFileSystem(), '/var/www/html', 'static_test');
  alkaidServer.httpModuleChain.add(staticHttpModule);
  staticHttpModule.cache('test/*');
  staticHttpModule.cache('abc/*');

  TestHttpModule.test();
  print(alkaidServer.httpModuleChain.toString());
  print(alkaidServer.httpModuleChain.toString());

}
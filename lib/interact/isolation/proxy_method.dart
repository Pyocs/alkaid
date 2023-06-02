
import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/tools/util/forward.dart';

///添加隔离处理方法(代理方式传递参数)
void addIsolateMethod(AlkaidServer alkaidServer,String path,String method,String uri) {
  if(!alkaidServer.httpModuleChain.contains('test')) {
    alkaidServer.httpModuleChain.add(RouterHttpModule('test',weight: 3));
  }
  RouterHttpModule routerHttpModule = alkaidServer.httpModuleChain.getByName('test')! as RouterHttpModule;
  routerHttpModule.addMethod(path, method, (request, response) async {
    forward(request, response,uri, method,out: true);
  });
}
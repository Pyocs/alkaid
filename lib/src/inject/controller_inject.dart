import 'dart:mirrors';

import '../../alkaid.dart';
import '../modules/route/route_meta.dart';

///控制器反射

void controllerScan(RouterHttpModule routerHttpModules,LibraryMirror libraryMirror) {

  libraryMirror.declarations.forEach((symbol, declaration) {
    if (declaration is ClassMirror) {
      //如果包含Controller注解
      if (declaration.metadata.any((element) =>
      element.reflectee is Controller)) {
        Controller controller = declaration.metadata
            .where((element) => element.reflectee is Controller)
            .first
            .reflectee as Controller;
        declaration.declarations.forEach((symbol, value) {
          if (value is MethodMirror && !value.isConstructor
              && !value.isConstConstructor && !value.isGetter &&
              !value.isSetter) {
            for (var meta in value.metadata) {
              if (meta.reflectee is GET || meta.reflectee is POST ||
                  meta.reflectee is PUT || meta.reflectee is DELETE ||
                  meta.reflectee is API) {
                HandlerRequest method;
                if (!value.isStatic) {
                  InstanceMirror instanceMirror = declaration.newInstance(
                      Symbol(''), []);
                  method = instanceMirror
                      .getField(symbol)
                      .reflectee as HandlerRequest;
                } else {
                  method = declaration
                      .getField(symbol)
                      .reflectee as HandlerRequest;
                }
                // method = declaration.getField(symbol).reflectee as HandlerRequest;
                switch (meta.reflectee.runtimeType) {
                  case GET :
                    GET get = meta.reflectee;
                    String path = '${controller.path}${get.path}'.replaceAll(
                        r'//', r'/');
                    routerHttpModules.get(path, method);
                    break;
                  case POST:
                    POST post = meta.reflectee;
                    String path = '${controller.path}${post.path}'.replaceAll(
                        r'//', r'/');
                    routerHttpModules.post(path, method);
                    break;
                  case PUT:
                    PUT put = meta.reflectee;
                    String path = '${controller.path}${put.path}'.replaceAll(
                        r'//', r'/');
                    routerHttpModules.put(path, method);
                    break;
                  case DELETE:
                    DELETE delete = meta.reflectee;
                    String path = '${controller.path}${delete.path}'.replaceAll(
                        r'//', r'/');
                    routerHttpModules.delete(path, method);
                    break;
                  case API:
                    API api = meta.reflectee;
                    String path = '${controller.path}${api.path}'.replaceAll(
                        r'//', r'/');
                    routerHttpModules.addMethod(path, api.method, method);
                    break;
                  default:
                    throw Exception('注解解析错误!');
                }
              }
            }
          }
        });
      }
    }
  });
}
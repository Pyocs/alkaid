import 'dart:mirrors';

import '../../alkaid.dart';
import '../modules/route/route_meta.dart';

///请求方法注入
///跳过控制器
///扫描请求方法注解(函数)
void methodScan(RouterHttpModule routerHttpModules,LibraryMirror libraryMirror) {
  //Class
  libraryMirror.declarations.forEach((symbol1, declaration) {
    if(declaration is ClassMirror || declaration is MethodMirror ) {
      //获取函数的所有注解
      //跳过控制器
      if(declaration is ClassMirror) {
        //如果所有注解都不是Controller
        if (!declaration.metadata.any((element) =>
        element.reflectee is Controller)) {
          declaration.declarations.forEach((symbol2, dec) {
            //寻找方法
            if (dec is MethodMirror && !dec.isGetter &&
                !dec.isSetter && !dec.isConstConstructor && !dec.isConstructor) {
              _reflect(dec, declaration, symbol2,routerHttpModules);
            }
          });
        }
      } //Method
      else {
        _reflect(declaration as MethodMirror, libraryMirror, symbol1,routerHttpModules);
      }
    }
  });

  // print(routerHttpModules.pathMapping);
}

void _reflect(MethodMirror declaration ,ObjectMirror declarationMirror,Symbol symbol,RouterHttpModule routerHttpModules) {
  for(var metadata in declaration.metadata) {
    if(metadata.reflectee is GET || metadata.reflectee is POST
        || metadata.reflectee is PUT || metadata.reflectee is DELETE || metadata.reflectee is API) {
      HandlerRequest method;
      // print(declarationMirror);

      if (declarationMirror is ClassMirror) {
        if(!declaration.isStatic) {
          method = declarationMirror.newInstance(Symbol(''), []).getField(symbol).reflectee;
        } else {
          method = declarationMirror
              .getField(symbol)
              .reflectee;
        }
      } else if (declarationMirror is InstanceMirror) {
        method = declarationMirror
            .getField(symbol)
            .reflectee;
      }
      else {
        method = (declarationMirror as LibraryMirror)
            .getField(symbol)
            .reflectee;
      }
      switch(metadata.reflectee.runtimeType) {
        case GET :
          GET get = metadata.reflectee;
          routerHttpModules.get(get.path,method);
          break;
        case POST:
          POST post = metadata.reflectee;
          routerHttpModules.post(post.path, method);
          break;
        case PUT:
          PUT put = metadata.reflectee;
          routerHttpModules.put(put.path,method);
          break;
        case DELETE:
          DELETE delete = metadata.reflectee;
          routerHttpModules.delete(delete.path, method);
          break;
        case API:
          API api = metadata.reflectee;
          routerHttpModules.addMethod(api.path, api.method,method);
          break;
        default:
          throw Exception('注解解析错误!');
      }
    }
  }
}
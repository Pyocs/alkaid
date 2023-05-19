import 'dart:async';
import 'dart:io';
import 'dart:convert';

import '../core/alkaid_server.dart';
import '../modules/route/route_meta.dart';
import '../status/alkaid_status.dart';
import '../tools/util/parse_param.dart' as param;



/// 服务，用于聚合一些需要依赖性的操作,获取封装一些常用的处理方法,对一些数据进行操作
/// 有两种服务，一种可以直接暴露给外部接口的RestfulAPI(挂载到AlkaidController)
/// 另一种为传统的服务，由控制器内部调用
abstract class AlkaidService {
  ///服务名称
  late final String name;

  ///服务入口
  Future accept(HttpRequest request,HttpResponse response);

  ///跳转到其他服务
  ///[serviceName] 要跳转的服务名称
  ///跳转到服务的accept方法
  Future jump(String serviceName,HttpRequest request,HttpResponse response) {
    return AlkaidServer.getServer().alkaidServiceManager.jump(name, request, response);
  }

  ///关闭服务
  FutureOr close();

  AlkaidService(this.name);

}

///可以直接挂载到控制器中暴露API
abstract class AlkaidExposeService extends AlkaidService {

  ///用于监听该Service路由的变化
  /// 'add' 该服务路由中添加了一个api
  /// 'remove' 该服务路由中移除了一个api
  /// 'done'   该服务路由不会再发生改变
  late  StreamController<Map<String,Map<String,RouterMeta?>?>>? _streamController;

  ///该服务路由是否可以改变
  late bool canChange;

  ///是否暴露
  late final bool expose;


  ///添加一个资源
  FutureOr add(dynamic param);

  ///修改一个资源
  FutureOr modify(dynamic param);

  ///删除一个资源
  FutureOr remove(dynamic param);

  ///检索资源
  FutureOr read(dynamic param);


  ///处理请求参素param
  @override
  Future accept(HttpRequest request,HttpResponse response) async {
    String method = request.method;
    switch(method) {
      case("GET"):
        return send(request, response, read(param.paramGET(request)));

      case("POST"):
        return send(request, response, add(await param.paramPOST(request)));

      case("PATCH"):
        return send(request, response, modify(await param.paramJson(request)));

      case("DELETE"):
        return send(request, response, remove(await param.paramJson(request)));
      default:return AlkaidStatus.fail;
    }
  }

  ///发送响应
  FutureOr send(HttpRequest request,HttpResponse response,dynamic content) {
    try{
      response.write(json.encode(content));
      response.close();
      return AlkaidStatus.finish;
    } catch(_) {
      return AlkaidStatus.fail;
    }
  }

  ///添加一个API
  void addRouter(String path,String method,HandlerRequest handlerRequest) {
    if(expose && canChange) {
      _streamController!.add(
          {
            "add":{
              path:RouterMeta(method,handlerRequest)
            }
          }
      );
    }
  }

  ///删除一个API
  void deleteRouter(String path,String method) {
    if(expose && canChange) {
      _streamController!.add({
        "delete":{
          '${path}_$method':null
        }
      });
    }
  }

  Stream? stream() {
    if(expose) {
      return _streamController!.stream;
    } else {
      return null;
    }
  }


  ///表示该服务的路由不会在发生改变
  ///如果执行该方法，该服务的API不可再改变
  void routeDone() {
    if(expose) {
      _streamController!.add({
        "done":null
      });
      canChange = false;
      _streamController!.close();
      _streamController = null;
    }
  }


  AlkaidExposeService(super.name,this.expose)  {
    if(expose == false) {
      _streamController = null;
      canChange = false;
    } else {
      _streamController = StreamController();
      canChange = true;
    }
  }
}

///内部调用
///可以使用Service注解依赖注入
abstract class AlkaidInternalService extends AlkaidService {

  AlkaidInternalService(super.name);

}

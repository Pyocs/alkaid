import 'dart:io';
import 'dart:async';

import '../core/alkaid_server.dart';
import '../exception/alkaid_server_exception.dart';
import '../modules/route/route_meta.dart';
import 'alkaid_service.dart';
import 'alkaid_service_manager.dart';

///钩子服务，用于给其他服务添加钩子服务
///不管服务是否暴露，拦截对accept方法的调用
///after  在A服务被执行之后执行B服务
class AlkaidHookedService extends AlkaidInternalService {
  //由该钩子代理的服务
  final AlkaidService inner;

  late AlkaidServiceManager _alkaidServiceManager;

  late final List<HandlerRequest> _handlers;

  AlkaidHookedService(super.name,this.inner) {
    _handlers = List.empty(growable: true);
    _handlers.add(inner.accept);
    _alkaidServiceManager = AlkaidServer.getServer().alkaidServiceManager;
  }

  //返回值为最后一个handler的结果
  @override
  Future accept(HttpRequest request, HttpResponse response) {
    Future result = Future.value();
    for(int i = 0 ; i < _handlers.length ; i++ ) {
      if(i == _handlers.length - 1) {
        result = _handlers[i].call(request, response);
      } else {
        _handlers[i].call(request,response);
      }
    }
    return result;
  }

  @override
  FutureOr close() {
    inner.close();
    _handlers.clear();
  }


  ///在A服务被执行之前执行B服务
  ///注意！：服务必须在ServicesManager中挂载
  ///如果代理的服务为ExposeService,并且有自定义API,则这些API统一处理
  ///[name] A服务的名称
  void before(String name) {
    AlkaidService? service = _alkaidServiceManager.getService(name);
    if(service == null) {
      throw AlkaidServerException("代理失败!$name没有挂载!");
    }
    _handlers.insert(0,service.accept);
  }

  ///在A服务被执行之前依次执行list里的所有服务
  ///[A] A服务的名称
  ///[list] 依次执行服务的名称，按照索引依次执行
  void beforeAll(List<String> list) {
    for(int i = 0 ; i < list.length ; i++) {
      AlkaidService? service = _alkaidServiceManager.getService(list[i]);
      if(service == null) {
        throw AlkaidServerException("代理失败!$name没有挂载!");
      } else {
        _handlers.insert(i, service.accept);
      }
    }
  }

  ///在服务被执行之后执行B服务
  void after(String name) {
    AlkaidService? service = _alkaidServiceManager.getService(name);
    if(service == null) {
      throw AlkaidServerException("代理失败!$name没有挂载!");
    }
    _handlers.insert(_handlers.length,service.accept);
  }

  void afterAll(List<String> list) {
    for(int i = 0 ; i < list.length ; i++) {
      AlkaidService? service = _alkaidServiceManager.getService(list[i]);
      if(service == null) {
        throw AlkaidServerException("代理失败!$name没有挂载!");
      } else {
        _handlers.insert(_handlers.length, service.accept);
      }
    }
  }


  void beforeExposeOneAPI(String name,String path,String method) {
    AlkaidService? alkaidService = _alkaidServiceManager.getService(name);
    if(alkaidService == null) {
      throw AlkaidServerException('$name服务没有挂载');
    }
    //根据name获取服务的accept方法
    _alkaidServiceManager.intercept(inner.name, path, method, alkaidService.accept, true);
  }

  void beforeExposeAllAPI(String name) {
    AlkaidService? alkaidService = _alkaidServiceManager.getService(name);
    if(alkaidService == null) {
      throw AlkaidServerException('$name服务没有挂载');
    }
    _alkaidServiceManager.interceptAll(inner.name, alkaidService.accept, true);
  }

  void afterExposeOneAPI(String name,String path,String method) {
    AlkaidService? alkaidService = _alkaidServiceManager.getService(name);
    if(alkaidService == null) {
      throw AlkaidServerException('$name服务没有挂载');
    }
    _alkaidServiceManager.intercept(inner.name,path,method,alkaidService.accept, false);
  }

  void afterExposeAllAPI(String name) {
    AlkaidService? alkaidService = _alkaidServiceManager.getService(name);
    if(alkaidService == null) {
      throw AlkaidServerException('$name服务没有挂载');
    }
    _alkaidServiceManager.interceptAll(inner.name, alkaidService.accept, false);
  }



}
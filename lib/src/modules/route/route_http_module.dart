import 'dart:io';
import 'dart:collection';
import 'package:io/ansi.dart';
import '../../exception/alkaid_http_exception.dart';
import '../../exception/alkaid_server_exception.dart';
import '../../status/alkaid_status.dart';
import 'route_meta.dart';
import '../http_module.dart';
///路由管理，控制器依赖它
// http://localhost:3000/:id{^\d+\w*$}/:name
class RouterHttpModule extends HttpModules {

  //路由映射
  final HashMap<String,List<RouterMeta>> _pathMapping = HashMap();

  //拦截器
  //string => path_method
  final Map<String,List<HandlerRequest>> _interceptor = HashMap();

  RouterHttpModule(String modulesName,{int? weight}) : super(modulesName,weight: weight);

  HashMap<String,List<RouterMeta>> get pathMapping => _pathMapping;


  @override
  Future check(HttpRequest request, HttpResponse response) {
    // TODO: implement check
    throw UnimplementedError();
  }

  @override
  Future finish(HttpRequest request, HttpResponse response) {
    // TODO: implement finish
    throw UnimplementedError();
  }

  @override
  Future handler(HttpRequest request, HttpResponse response) {
    try {
      String name = '${request.uri.path}_${request.method}';
      if(_interceptor.containsKey(name)) {
        dynamic result ;
        //如果某个拦截方法返回AlkaidStatus.fail,则直接将结果返回个模块链
        for(int i = 0 ; i < _interceptor[name]!.length ; i ++) {
          result = _interceptor[name]![i].call(request,response);
          if(i != _interceptor[name]!.length -1) {
            if(result is AlkaidStatus && result == AlkaidStatus.fail) {
              return Future.value(result);
            }
          }
        }
        return result;
      }
      var handlerFunction = find(request.uri.path, request.method);
      if(handlerFunction == null) {
        throw AlkaidHttpException.notFound();
      }
      return handlerFunction.call(request,response);
    } on StateError catch(_) {
      throw AlkaidHttpException.methodNotAllowed();
    }

  }

  ///添加get请求
  void get(String path,HandlerRequest handlerRequest) => addMethod(path, 'GET', handlerRequest);

  ///添加post请求
  void post(String path,HandlerRequest handlerRequest) => addMethod(path, 'POST', handlerRequest);

  ///添加put请求
  void put(String path,HandlerRequest handlerRequest) => addMethod(path, 'PUT', handlerRequest);

  ///添加delete请求
  void delete(String path,HandlerRequest handlerRequest) => addMethod(path, 'DELETE',handlerRequest);

  ///删除请求方法,如果method为null,则删除所有
  ///如果拦截器中有该方法(method不能为null),则从拦截器中移除该API
  bool removeMethod(String path,{String? method}) {
    if(_pathMapping[path] == null) {
      return false;
    }
    if(method != null) {
      _pathMapping[path]!.removeWhere((element) {
        return element.method.toLowerCase() == method.toLowerCase();
      });
      //删除完后如果path没有其他方法，则清空
      if(_pathMapping[path]!.isEmpty) {
        _pathMapping.remove(path);
      }
    } else {
      _pathMapping.remove(path);
      if(_interceptor.containsKey('${path}_$method')) {
        _interceptor.remove('${path}_$method');
      }
    }
    return true;
  }


  ///寻找处理方法
  HandlerRequest? find(String path,String method) {
    return _pathMapping[path] == null ?  null :
    _pathMapping[path]!.where((element) => element.method.toLowerCase() == method.toLowerCase()).first.handlerRequest;
  }


  ///添加一个方法
  void addMethod(String path,String method,HandlerRequest handlerRequest) {
    if(!path.startsWith('/')) path = '/$path';

    if(_pathMapping.containsKey(path)) {
      _pathMapping[path]!.removeWhere((element) {
        bool tar =  element.method.toLowerCase() == method.toLowerCase();
        if(tar) {
          print(yellow.wrap('含有重复路由，已替换!  $method $path'));
          return true;
        }
        return false;
      });
    }

    _pathMapping[path] == null ?
    _pathMapping.addEntries({path:[RouterMeta(method,handlerRequest)]}.entries) :
    _pathMapping[path]!.add(RouterMeta(method,handlerRequest));
  }

  ///路由表中是否包含指定API
  bool hasAPI(String path,String method) {
    if(_pathMapping[path] == null) {
      return false;
    } else {
      return _pathMapping[path]!.any((element) => element.method == method);
    }
  }

  @override
  Future later(HttpRequest request, HttpResponse response) {
    // TODO: implement later
    throw UnimplementedError();
  }

  ///配置拦截器
  ///在a请求之后执行方法b
  void after(String path,String method,HandlerRequest handlerRequest) {
    String name = '${path}_${method.toUpperCase()}';
    if(!_interceptor.containsKey(name)) {
      _interceptor[name] = [find(path, method)!];
    }
    _interceptor[name]!.insert(_interceptor[name]!.length,handlerRequest);
  }


  ///配置拦截器
  ///在请求之前执行方法
  void before(String path,String method,HandlerRequest handlerRequest) {
    if(!hasAPI(path, method)) {
      throw AlkaidServerException('路由表中没有该方法:$path,$method');
    }

    String name = '${path}_${method.toUpperCase()}';
    if(!_interceptor.containsKey(name)) {
      _interceptor[name] = [find(path, method)!];
    }
    _interceptor[name]!.insert(0,handlerRequest);
  }
}
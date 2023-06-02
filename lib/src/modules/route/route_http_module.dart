import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:alkaid/src/modules/route/default_serialization.dart';
import 'package:io/ansi.dart';
import '../../exception/alkaid_http_exception.dart';
import '../../exception/alkaid_server_exception.dart';
import '../../status/alkaid_status.dart';
import 'route_meta.dart';
import '../http_module.dart';
import 'serialization.dart';
///路由管理，控制器依赖它
// http://localhost:3000/download/#${\d+}[abc|cd]/
class RouterHttpModule extends HttpModules {

  //路由映射
  final HashMap<String,List<RouterMeta>> _pathMapping = HashMap();
  //拦截器
  //string => path_method
  final Map<String,List<HandlerRequest>> _interceptor = HashMap();
  //保存正则表达式请求uri
  final List<List<RegExp>> _regExpMapping = List.empty(growable: true);
  late final Serialization _serialization;
  //全局拦截器
  final List<HandlerRequest> _globalInterceptorBefore = [];
  final List<HandlerRequest> _globalInterceptorAfter = [];

  RouterHttpModule(String modulesName,{int? weight,Serialization? serialization}) : super(modulesName,weight: weight) {
   if(serialization == null) {
     _serialization = DefaultSerialization();
   } else {
     _serialization = serialization;
   }
  }

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
  dynamic handler(HttpRequest request, HttpResponse response) {
    try {
      /*
        执行顺序是   Before全局拦截器 ->  局部拦截器  -> 请求方法 --> After全局拦截器
          全局拦截器只会对返回结果为AlkaidStatus进行处理，如果返回其他类型，则将忽略
          局部拦截器和请求方法会对任何返回结果进行处理
            对于Future,如果返回null和AlkaidStatus则忽略，其他结果进行序列化后写入响应
            普通结果返回
            最后关闭响应
          //如果返回结果是AlkaidStatus,则不要用使用Future
       */
      //Before全局拦截器
      if(_globalInterceptorBefore.isNotEmpty) {
        for(int i = 0 ; i < _globalInterceptorBefore.length ; i++) {
          var result = _globalInterceptorBefore[i].call(request,response);
          if(result is AlkaidStatus) {
            return Future.value(result);
          }
        }
      }

      //局部拦截器
      String name = '${request.uri.path}_${request.method}';
      if(_interceptor.containsKey(name)) {
        dynamic result ;
        List<Completer>? temp;
        bool hasFuture = false;
        //如果某个拦截方法返回AlkaidStatus.status,则直接将结果返回个模块链
        for(int i = 0 ; i < _interceptor[name]!.length ; i ++) {
          result = _interceptor[name]![i].call(request,response);
          if(i != _interceptor[name]!.length -1 && result is AlkaidStatus) {
              return Future.value(result);
          }
          //对于局部拦截器返回的结果，null忽略，其他序列化写入响应
          if(result is Future) {
            hasFuture = true;
            temp ??= [];
            Completer completer = Completer();
            temp.add(completer);
            result.then((value) {
              if(value != null && value.runtimeType !=  AlkaidStatus) {
                response.write(_serialization.serial(value));
              }
              completer.complete();
            });
          } else {
            if(result != null && result.runtimeType != AlkaidStatus) {
              response.write(_serialization.serial(result));
            } else {
              return Future.value(result);
            }
          }
        }
        if(hasFuture) {
          //等待所有Future完成关闭response
          Future.wait(temp!.map((e) => e.future)).then((_) {
            temp!.clear();
            if(_globalInterceptorAfter.isNotEmpty) {
              for(int i = 0 ; i < _globalInterceptorAfter.length ; i++) {
                var t = _globalInterceptorAfter[i].call(request,response);
                if(t is AlkaidStatus) {
                  return t;
                }
              }
            }
            response.close();
          });
        } else {
          if(_globalInterceptorAfter.isNotEmpty) {
            for(int i = 0 ; i < _globalInterceptorAfter.length ; i++) {
              var result = _globalInterceptorAfter[i].call(request,response);
              if(result is AlkaidStatus) {
                return Future.value(result);
              }
            }
          }
          response.close();
        }
        return Future.value(AlkaidStatus.finish);
      }

      var handlerFunction = find(request.uri.path, request.method);
      handlerFunction ??= _regExpFind(request.uri.path, request.method);
      if(handlerFunction == null) {
        throw AlkaidHttpException.notFound();
      }
      var result = handlerFunction.call(request,response);
      return _handlerResult(request, response, result);
    } on StateError catch(_) {
      throw AlkaidHttpException.methodNotAllowed();
    }
  }


  Future _handlerResult(HttpRequest request,HttpResponse response,dynamic result) {
     if(result is Future) {
       result.then((value) {
         if(value != null && value.runtimeType != AlkaidStatus) {
           response.write(_serialization.serial(value));
         }
         if(_globalInterceptorAfter.isNotEmpty) {
           for(int i = 0 ; i < _globalInterceptorAfter.length ; i++) {
             var t = _globalInterceptorAfter[i].call(request,response);
             if(t is AlkaidStatus) {
               return t;
             }
           }
         }
         response.close();
       });
      return Future.value(AlkaidStatus.finish);
    } else {
       if(_globalInterceptorAfter.isNotEmpty) {
         for(int i = 0 ; i < _globalInterceptorAfter.length ; i++) {
           var result = _globalInterceptorAfter[i].call(request,response);
           if(result is AlkaidStatus) {
             return Future.value(result);
           }
         }
       }
       if(result == null) {
         response.close();
       } else if(result.runtimeType == AlkaidStatus) {
         return Future.value(result);
       } else {
         response.write(_serialization.serial(result));
         response.close();
       }
       return Future.value(AlkaidStatus.finish);
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
    if(path.contains('#')) {
      path = path.replaceAll('#', '');
      var split = path.split('/');
      // split.removeWhere((element) => element == "");
      List<RegExp> temp = [];
      for(int i = 0 ; i < split.length ; i++) {
        temp.add(RegExp(split[i]));
      }
      _regExpMapping.add(temp);
    }
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

  //根据正则表达式寻找请求方法
  HandlerRequest? _regExpFind(String path,String method) {
    var split = path.split('/');
    // split.removeWhere((element) => element == "");
    for(int i = 0 ; i < _regExpMapping.length ; i++) {
      List<RegExp> list = _regExpMapping[i];
      int k = 0;
      for(int j = 0 ; j < list.length && j < split.length; j++) {
        if(!list[j].hasMatch(split[j])) {
          break;
        } else {
          ++k;
        }
      }
      if(k == split.length) {
        //匹配成功
        return _pathMapping[list.map((e) => e.pattern).join('/')]?.firstWhere((element) => element.method.toLowerCase() == method.toLowerCase()).handlerRequest;
      }
    }
    return null;
  }

  ///在所有方法执行后执行
  void afterAll(HandlerRequest handlerRequest) {
   _globalInterceptorAfter.insert(_globalInterceptorAfter.length, handlerRequest);
  }

  ///在所有方法执行前执行
  void beforeAll(HandlerRequest handlerRequest) {
    _globalInterceptorBefore.insert(0, handlerRequest);
  }
}
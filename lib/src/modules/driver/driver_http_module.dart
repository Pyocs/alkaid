import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import '../../core/http_context_meta.dart';
import '../../exception/alkaid_exception.dart';
import '../../exception/alkaid_http_exception.dart';
import '../../exception/alkaid_server_exception.dart';
import '../../core/modules_collection.dart';
import '../../status/alkaid_status.dart';
import '../http_module.dart';
import '../../logging/alkaid_logging.dart';
import 'http_module_chain.dart';


///协调HTTP模块，发送响应
///
/// 模块返回状态码，决定下一步处理步骤
/// AlkaidStatus.finish 处理完成，已经关闭httpResponse，提前结束模块链循环
/// AlkaidStatus.fail   处理失败，抛出AlkaidException
///   fail失败后，如果为模块链最后一个模块，且异常为AlkaidHttpException,则将该异常交给异常处理模块处理
///   如果为模块链最后一个模块，且异常不是AlkaidHttpException,则抛出AlkaidHttpException.internalServerError
///   如果不是模块链最后一个异常，则将异常信息写入事件总线，接着由下一个模块处理，如果下一个模块也抛出异常且异常信息不同，则替换前一个异常
///   如果下一个模块能正常处理请求且返回响应，则返回AlkaidStatus.finish
///
/// AlkaidStatus.stop  表明响应没有直接写入，而是写入了事件总线，且response没有关闭，而由序列化模块从事件总线读取响应并序列化响应、关闭响应
/// AlkaidStatus.stop会提前结束模块链的循环
/// AlkaidStatus.wait  该模块展示不能处理该请求，需要其他模块协同才能处理
///  *** 这种情况需要其他模块将响应写入事件总线，然后由该模块从事件模块中读取、处理 (实现最难)
///
///如果返回其他其他值，则序列化
///
///
/// 在事件总线中怎么分辨不同的Request?   key-value  key要唯一  key=ip+method+path+n?
class DriverHttpModule implements HttpModules {

  late final HttpModuleChain httpModuleChain;

  @override
  late final ModulesCollection modulesCollection;

  late final AlkaidLogging alkaidLogging;

  DriverHttpModule(this.httpModuleChain,this.modulesCollection,this.alkaidLogging);

  @override
  String name = 'Driver';

  @override
  int weight = -1;


  @override
  Future finish(HttpRequest request, HttpResponse response) {
    // TODO: implement finish
    throw UnimplementedError();
  }

  @override
  void handler(HttpRequest request, HttpResponse response) async {
    //获取第一个处理模块
    HttpModules? httpModules = httpModuleChain.get(-1, '');
    if(httpModules == null) {
      response.write(AlkaidHttpException.notFound().message);
      response.close();
      return ;
    }

    _handlerResult(httpModules, request, response);
  }

  ///处理模块返回值
  void _handlerResult(HttpModules httpModules,HttpRequest request,HttpResponse response) async {
    runZonedGuarded(() {
      httpModules.handler(request, response).then((value) {
        //处理返回状态码
        if (value is AlkaidStatus) {
          switch (value) {
            case AlkaidStatus.finish:
              _cleanRequest(request);
              return;
            case AlkaidStatus.fail:
              HttpModules? module = httpModuleChain.next(httpModules);
              //模块链最后一个模块
              if (module == null) {
                _lastModule(request, response);
              } else {
                return _handlerResult(module, request, response);
              }
              break;
            case AlkaidStatus.stop:
              _lastModule(request, response);
              return;
            case AlkaidStatus.wait:
              HttpModules? module = httpModuleChain.next(httpModules);
              if (module == null) {
                _lastModule(request, response);
                return;
              }
              module.write = true;
              httpModules.later(request, response);
              return _handlerResult(module, request, response);
            default:
              throw AlkaidHttpException.internalServerError();
          }
        } else {
           _serialization(request, response, value);
        }
      });
    },(err,stack){
      //发生了异常
      _handlerError(err, stack, request);
      HttpModules? module = httpModuleChain.next(httpModules);
      if(module == null) {
        _lastModule(request, response);
      } else {
        return _handlerResult(module, request, response);
      }
    });
  }


  ///处理错误
  void _handlerError(err,stack,HttpRequest request) {
    modulesCollection.add(HttpContextMeta(request, err));
  }

  ///发送错误
  void _sendError(HttpRequest request,HttpResponse response,AlkaidException alkaidException ) {
    if(alkaidException is AlkaidServerException) {
      _logServer(alkaidException,Level.INFO);
      return ;
    }
    try {
      response.headers.contentType = ContentType.html;
      response.statusCode = (alkaidException as AlkaidHttpException).code;
      response.write((alkaidException).message);
      response.close();
      _logHttp(request, response);
    } catch(err) {
      print(err);
    }finally{
      _cleanRequest(request);
    }
  }

  void _sendResponse(HttpRequest request,HttpResponse response,dynamic value) {
    try {
      response.write(value);
      response.close();
    } catch(err) {
      print(err);
    }finally{
      _cleanRequest(request);
    }
  }

  void _logHttp(HttpRequest request,HttpResponse response) {
    alkaidLogging.httpLog(request, response);
  }

  void _logServer(AlkaidServerException alkaidServerException,Level level) {
    alkaidLogging.serverLog(alkaidServerException, level);
  }

  dynamic _serialization(HttpRequest request,HttpResponse response,dynamic value) {
    if(value == null) {
      // _cleanRequest(request);
      return ;
    }
    response.write(value.toString());
    response.close();
    _cleanRequest(request);
    return ;
  }

  @override
  Future check(HttpRequest request, HttpResponse response) {
    // TODO: implement check
    throw UnimplementedError();
  }

  @override
  final bool write = false;

  @override
  Future later(HttpRequest request, HttpResponse response) {
    // TODO: implement later
    throw UnimplementedError();
  }

  @override
  set write(bool write) {
    // TODO: implement write
    throw UnimplementedError();
  }


  void _cleanRequest(HttpRequest request) => modulesCollection.remove(request);

  //遍历到模块链最后一个模块
  void _lastModule(HttpRequest request,HttpResponse response) {
    var value = modulesCollection.get(request);
    if(value is AlkaidHttpException) {
      _sendError(request, response, value);
    } else if( value is Exception || value is Error) {
      _sendError(request, response, AlkaidHttpException.internalServerError());
    } else if(value == null){
      _sendResponse(request, response, AlkaidHttpException.notFound());
    } else {
      _sendResponse(request, response, value);
    }
  }
}
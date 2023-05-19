import 'dart:io';
import 'package:alkaid/src/service/alkaid_service_manager.dart';
import 'package:file/local.dart';
import 'package:io/ansi.dart';
import '../exception/alkaid_server_exception.dart';
import '../inject/alkaid_inject.dart';
import '../modules/driver/alkaid_logging.dart';
import '../modules/driver/driver_http_module.dart';
import '../modules/driver/http_module_chain.dart';
import '../modules/route/route_http_module.dart';
import 'modules_collection.dart';
import '../modules/static/static_http_module.dart';


class AlkaidServer {
  static  late final  AlkaidServer? _alkaidServer;
  late final int _sessionTimeout;

  late final HttpServer _httpServer;
  //日志
  late final AlkaidLogging _alkaidLogging;
  //模块链
  late final HttpModuleChain _httpModuleChain;
  //事件总线
  late final ModulesCollection _modulesCollection;
  //路由模块
  late final  RouterHttpModule _routerHttpModule;
  //静态资源模块
  late final StaticHttpModule _staticHttpModule;
  late final DriverHttpModule _driverHttpModule;
  //服务管理器
  late final AlkaidServiceManager _alkaidServiceManager;

  late final bool _hasSecure;

  int get sessionTimeout => _sessionTimeout;
  HttpModuleChain get httpModuleChain => _httpModuleChain;
  ModulesCollection get modulesCollection => _modulesCollection;
  RouterHttpModule get routerHttpModule => _routerHttpModule;
  StaticHttpModule get staticHttpModule => _staticHttpModule;
  AlkaidServiceManager get alkaidServiceManager => _alkaidServiceManager;

  bool get hasSecure => _hasSecure;
  AlkaidServer._();

  static Future<AlkaidServer> server(dynamic address,int port,{bool shared = false,int? sessionTimeout}) async {
    AlkaidServer alkaidServer = AlkaidServer._();
    alkaidServer._httpServer = await HttpServer.bind(address, port,shared: shared);
    alkaidServer._hasSecure = false;
    if(sessionTimeout != null) {
      alkaidServer._httpServer.sessionTimeout = sessionTimeout;
      alkaidServer._sessionTimeout = sessionTimeout;
    } else {
      alkaidServer._sessionTimeout = 1200;
    }

    return alkaidServer;
  }

  static Future<AlkaidServer> secureServer(dynamic address,int port,SecurityContext context,{bool shared = false,int? sessionTimeout}) async {
    AlkaidServer alkaidServer = AlkaidServer._();
    alkaidServer._httpServer = await HttpServer.bindSecure(address, port, context,shared: shared);
    alkaidServer._hasSecure = true;
    if(sessionTimeout != null) {
      alkaidServer._httpServer.sessionTimeout = sessionTimeout;
    }
    return alkaidServer;
  }

  void _init() {
    _alkaidServer = this;
    _alkaidLogging = AlkaidLogging();
    _modulesCollection = ModulesCollection();
    _httpModuleChain = HttpModuleChain();
    _routerHttpModule = RouterHttpModule('router',weight: 5);
    _staticHttpModule = StaticHttpModule(LocalFileSystem(), 'web', 'static',weight: 4);
    _httpModuleChain.addAll([_routerHttpModule,_staticHttpModule]);
    _driverHttpModule = DriverHttpModule(_httpModuleChain, _modulesCollection, _alkaidLogging);
    _alkaidServiceManager = AlkaidServiceManager(_routerHttpModule);
  }


  Future<void> start() async {
    print(blue.wrap(
        '''
    ___     __    __              _        __
   /   |   / /   / /__  ____ _   (_)  ____/ /
  / /| |  / /   / //_/ / __ `/  / /  / __  / 
 / ___ | / /   / ,<   / /_/ /  / /  / /_/ /  
/_/  |_|/_/   /_/|_|  \__,_/  /_/   \__,_/   
                                             
    '''
    ));

    print(blue.wrap('夜幕降临之际，火光摇曳妩媚、灿烂多姿，是最美最美的… …'));

    //反射注入
    _init();
    await AlkaidInject(_routerHttpModule).start();

    _httpServer.listen((HttpRequest request) {
      _driverHttpModule.handler(request, request.response);
    });
    _httpServer.defaultResponseHeaders.add('Server', 'Alkaid');
    print(yellow.wrap('listen:  ${_hasSecure ? "https:" : "http:"}${_httpServer.address.host}:${_httpServer.port}'));
  }

  void close() async {
    _httpServer.close();
    _modulesCollection.close();
    _alkaidLogging.close();
  }

  ///获取Server
  static AlkaidServer getServer() {
    if(_alkaidServer == null) {
      throw AlkaidServerException('服务没有实例化');
    }
    return _alkaidServer!;
  }
}


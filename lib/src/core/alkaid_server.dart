import 'dart:io';
import 'package:alkaid/src/service/alkaid_service_manager.dart';
import 'package:file/local.dart';
import 'package:io/ansi.dart';

import '../exception/alkaid_server_exception.dart';
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

  late final AlkaidLogging alkaidLogging;

  final HttpModuleChain httpModuleChain = HttpModuleChain();

  final ModulesCollection modulesCollection = ModulesCollection();

  late final  RouterHttpModule routerHttpModule;

  late final StaticHttpModule staticHttpModule;

  late final DriverHttpModule driverHttpModule;

  late final AlkaidServiceManager alkaidServiceManager;

  late final bool _hasSecure;

  int get sessionTimeout => _sessionTimeout;

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
    alkaidLogging = AlkaidLogging();
    routerHttpModule = RouterHttpModule('router',weight: 5);
    staticHttpModule = StaticHttpModule(LocalFileSystem(), 'web', 'static',weight: 4);
    httpModuleChain.addAll([routerHttpModule,staticHttpModule]);
    driverHttpModule = DriverHttpModule(httpModuleChain, modulesCollection, alkaidLogging);
    alkaidServiceManager = AlkaidServiceManager(routerHttpModule);
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
    // await AlkaidInject(routerHttpModules).start();

    _httpServer.listen((HttpRequest request) {
      driverHttpModule.handler(request, request.response);
    });
    _httpServer.defaultResponseHeaders.add('Server', 'Alkaid');
    print(yellow.wrap('listen:  ${_hasSecure ? "https:" : "http:"}${_httpServer.address.host}:${_httpServer.port}'));
  }

  void close() async {
    _httpServer.close();
    modulesCollection.close();
    alkaidLogging.close();
  }

  ///获取Server
  static AlkaidServer getServer() {
    if(_alkaidServer == null) {
      throw AlkaidServerException('服务没有实例化');
    }
    return _alkaidServer!;
  }
}


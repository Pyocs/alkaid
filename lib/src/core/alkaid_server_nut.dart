import 'dart:io';

import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/core/modules_collection.dart';
import 'package:alkaid/src/logging/alkaid_logging.dart';
import 'package:alkaid/src/modules/driver/http_module_chain.dart';
import 'package:io/ansi.dart';

class AlkaidServerNut {
  static  late final  AlkaidServerNut? _alkaidServer;
   final HttpServer httpServer;
   final AlkaidLogging alkaidLogging;
   final DriverHttpModule driverHttpModule;
   final HttpModuleChain httpModuleChain;
   final ModulesCollection modulesCollection;
   final bool _hasSecure = false;

  bool get hasSecure => _hasSecure;

  AlkaidServerNut({
    required this.httpServer,
    required this.alkaidLogging,
    required this.httpModuleChain,
    required this.driverHttpModule,
    required this.modulesCollection
  });




  Future<void> start() async {
    print(blue.wrap(
        '''
    ___     __    __              _        __
   /   |   / /   / /__  ____ _   (_)  ____/ /
  / /| |  / /   / //_/ / __ `/  / /  / __  / 
 / ___ | / /   / ,<   / /_/ /  / /  / /_/ /  
/_/  |_|/_/   /_/|_| /__,_/  /_/   /__,_/   
                                             
    '''
    ));

    print(blue.wrap('夜幕降临之际，火光摇曳妩媚、灿烂多姿，是最美最美的… …'));

    //反射注入


    httpServer.listen((HttpRequest request) {
      driverHttpModule.handler(request, request.response);
    });
    httpServer.defaultResponseHeaders.add('Server', 'Alkaid');
    print(yellow.wrap('listen:  ${_hasSecure ? "https:" : "http:"}${httpServer.address.host}:${httpServer.port}'));
  }


  void close() async {
    httpServer.close();
    modulesCollection.close();
    alkaidLogging.close();
  }

  ///获取Server
  static AlkaidServerNut getServer() {
    if(_alkaidServer == null) {
      throw AlkaidServerException('服务没有实例化');
    }
    return _alkaidServer!;
  }

}
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/core/alkaid_server_nut.dart';
import 'package:alkaid/src/core/modules_collection.dart';
import 'package:alkaid/src/logging/alkaid_logging.dart';
import 'package:alkaid/src/modules/driver/http_module_chain.dart';
import 'package:file/local.dart';
import 'package:io/ansi.dart';

void main() async {
  ReceivePort receivePort = ReceivePort();
  ModulesCollection modulesCollection = ModulesCollection();
 Isolate.spawn(test,modulesCollection);
 Isolate.spawn(test,modulesCollection);
 Isolate.spawn(test,modulesCollection);
}

void test(ModulesCollection modulesCollection) async {
  HttpServer httpServer = await  HttpServer.bind('localhost', 3000,shared: true);
  AlkaidLogging alkaidLogging = AlkaidLogging();
  HttpModuleChain httpModuleChain = HttpModuleChain();
  // ModulesCollection modulesCollection = ModulesCollection();
  DriverHttpModule driverHttpModule = DriverHttpModule(httpModuleChain, modulesCollection, alkaidLogging);

  StaticHttpModule staticHttpModule = StaticHttpModule(LocalFileSystem(), '/var/www/html', 'static');
  httpModuleChain.add(staticHttpModule);

  AlkaidServerNut alkaidServerNut = AlkaidServerNut(
      httpServer: httpServer,
      alkaidLogging: alkaidLogging,
      httpModuleChain: httpModuleChain,
      modulesCollection: modulesCollection,
      driverHttpModule: driverHttpModule
  );

  alkaidServerNut.start();
  print(modulesCollection.hashCode);
}

void test2(int i ) async {
  int count = 0;
 AlkaidServer alkaidServer = await AlkaidServer.server('localhost', 3000,shared: true,inject: false);
 alkaidServer.start();
 alkaidServer.routerHttpModule.get('/time', (request, response) {
   count++;
   return DateTime.now();
 });

 Timer.periodic(Duration(seconds: 5), (timer) {
   print(yellow.wrap('线程$i执行次数:$count\t'));
 });
}
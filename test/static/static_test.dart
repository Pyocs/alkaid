import 'dart:async';
import 'dart:io';

import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/tools/util/parse_param.dart';
import 'package:alkaid/src/tools/util/parse_regexp.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';

void main() async {
  AlkaidServer alkaidServer = await AlkaidServer.server('0.0.0.0', 3000,inject: false);
  await alkaidServer.start();

  StaticHttpModule staticHttpModule = StaticHttpModule(LocalFileSystem(), '/opt/alkaid/web', 'static_test',weight: 1,allowDirectoryListing: true);
  alkaidServer.httpModuleChain.add(staticHttpModule);
  alkaidServer.httpModuleChain.delete('static');

  alkaidServer.routerHttpModule.get('/test', (request, response) {
    response.write(paramGET(request));
    response.close();
    return Future.value();
  });

  alkaidServer.routerHttpModule.get(r'/download/#^[a-zA-Z]+$', (request, response) {
    response.write('匹配英文');
    response.close();
    return Future.value(AlkaidStatus.finish);
  });

  alkaidServer.routerHttpModule.get(r'/download/#^[0-9]+$', (request, response) {
    response.write('匹配数字');
    response.close();
    print(parseRegExp(r'/download/#^[0-9]+$',request.uri.path ));
    return Future.value(AlkaidStatus.finish);
  });

  alkaidServer.routerHttpModule.get(r'/download/#^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$', (request, response) {
    response.write('匹配邮箱');
    response.close();
    return Future.value(AlkaidStatus.finish);
  });


  alkaidServer.routerHttpModule.get(r'/download/#aaa.zip', (request, response) {
    response.write('Hello world');
    response.close();
    return Future.value(AlkaidStatus.finish);
  });

  staticHttpModule.download('out.dart', '/downloads');
  staticHttpModule.download('example', '/downloaddir');

  // Timer.periodic(Duration(seconds: 5), (timer) {
  //   print(alkaidServer.modulesCollection.length);
  // });

  alkaidServer.routerHttpModule.get('/hello', (request, response) {
    return "Hello world";
  });

  alkaidServer.routerHttpModule.get('/aaa', (request, response) async {
    await Future.delayed(Duration(seconds: 3));
    response.write(DateTime.now());
  });

  alkaidServer.routerHttpModule.get('/bbb', (request, response) => AlkaidStatus.stop);

  alkaidServer.routerHttpModule.get('/ccc', (request, response) => Future.value('Hello Dart'));

  alkaidServer.routerHttpModule.before('/ccc', 'GET', (request, response) {
    response.write('哈哈哈哈哈');
  });

  alkaidServer.routerHttpModule.after('/ccc', 'GET', (request, response) {
    print("啦啦啦啦啦");
  });

  alkaidServer.routerHttpModule.after('/ccc', 'GET', (request, response) => Future.delayed(Duration(seconds: 3)));

  alkaidServer.routerHttpModule.before('/ccc', 'GET', (request, response) => AlkaidStatus.stop);

  alkaidServer.routerHttpModule.beforeAll((request, response) {
    print('11111111');
  });

  alkaidServer.routerHttpModule.afterAll((request, response) {
    print("2222222");
  });

}
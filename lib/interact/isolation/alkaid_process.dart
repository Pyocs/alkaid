import 'dart:io';
import 'package:alkaid/src/inject/alkaid_inject.dart';
import '../../alkaid.dart';

class AlkaidProcess {
  late final AlkaidServer alkaidServer;

  AlkaidProcess()  {
   _init();
  }

  void _init() async {
    alkaidServer = await AlkaidServer.server('localhost', 3000);
    await alkaidServer.start();
  }

  void close() {
    alkaidServer.close();
  }

  void reloadInject()  {
    AlkaidInject(alkaidServer.routerHttpModule).start();
  }
}


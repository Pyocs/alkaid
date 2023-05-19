import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';

class AlkaidLogging {
  final String _dirName = '/var/log/alkaid';
  final String _httpName = '/var/log/alkaid/http.log';
  final String  _serverName = '/var/log/alkaid/server.log';

  final Logger httpLogger = Logger("http");
  final Logger serverLogger = Logger("server");


  late final RandomAccessFile rs1;
  late final RandomAccessFile rs2;

  late StreamSubscription<LogRecord> httpStream;
  late StreamSubscription<LogRecord> serverStream;


  AlkaidLogging() {
    _init();
  }

  void _init() {
    hierarchicalLoggingEnabled = true;
    serverLogger.level =  httpLogger.level = Level.ALL;
    Directory directory = Directory(_dirName);
    File file1 = File(_httpName);
    File file2 = File(_serverName);

    rs1 = file1.openSync(mode: FileMode.append);
    rs2 = file2.openSync(mode: FileMode.append);


    directory.createSync();
    httpStream = httpLogger.onRecord.listen((event)  async {
      // ip date method path device
      rs1.writeStringSync('${event.message}\n');
    });

    serverStream = serverLogger.onRecord.listen((event)  async {
      rs2.writeString('${event.message}\n');
    });
  }

  void close() async{
    await rs1.close();
    await rs2.close();
    await httpStream.cancel();
    await serverStream.cancel();
  }
}
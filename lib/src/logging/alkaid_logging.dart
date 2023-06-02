import 'dart:io';
import 'dart:async';
import 'package:alkaid/alkaid.dart';
import 'package:logging/logging.dart';

class AlkaidLogging {
  late final bool _openLog;
  late final String _dirName;
  late final String _httpName;
  late final String  _serverName;
  late final String _errorName;

  late final Logger _httpLogger;
  late final Logger _serverLogger;
  late final Logger _errorLogger;

  late final RandomAccessFile _rs1;
  late final RandomAccessFile _rs2;
  late final RandomAccessFile _rs3;

  late final StreamSubscription<LogRecord> _httpStream;
  late final StreamSubscription<LogRecord> _serverStream;
  late final StreamSubscription<LogRecord> _errorStream;
  bool get openLog => _openLog;

  AlkaidLogging({bool openLog = true,String? logDirectory}) {
    _openLog = openLog;
    if(logDirectory != null) {
      _dirName = logDirectory;
    } else {
      if(Platform.isLinux) {
        _dirName = '/var/log/alkaid';
      } else {
        _dirName = 'log';
      }
    }
    _httpName = '$_dirName/http.log';
    _serverName = '$_serverName/server.log';
    _errorName = '$_errorName/error.log';
    _init();
  }

  void _init() {
    if(!_openLog) {
      return ;
    }
    Directory directory = Directory(_dirName);
    if(!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    hierarchicalLoggingEnabled = true;
    _httpLogger = Logger('http');
    _serverLogger = Logger('server');
    _errorLogger = Logger('error');

    _httpLogger.level = Level.INFO;
    _serverLogger.level = Level.INFO;
    _errorLogger.level = Level.ALL;
    File file1 = File(_httpName);
    File file2 = File(_serverName);
    File file3 = File(_errorName);

    _rs1 = file1.openSync(mode: FileMode.append);
    _rs2 = file2.openSync(mode: FileMode.append);
    _rs3 = file3.openSync(mode: FileMode.append);

    _httpStream = _httpLogger.onRecord.listen((event)  async {
      // ip date method path device
      _rs1.writeStringSync('${event.message}\n');
    });

    _serverStream = _serverLogger.onRecord.listen((event)  async {
      _rs2.writeString('${event.level}  ${event.time}  ${event.message}  ${event.error}\n');
    });

    _errorStream = _errorLogger.onRecord.listen((event) {
      _rs3.writeStringSync('${event.level}  ${event.time}  ${event.message}  ${event.error}  ${event.stackTrace}\n');
    });


  }

  void close() async{
    await _rs1.close();
    await _rs2.close();
    await _rs3.close();
    await _httpStream.cancel();
    await _serverStream.cancel();
    await _errorStream.cancel();
  }

  void httpLog(HttpRequest request,HttpResponse response) {
    _httpLogger.info('${request.connectionInfo?.remoteAddress.host} -- [${DateTime.now().toIso8601String()}] ${request.method} ${request.uri.path} ${response.statusCode} ${request.headers.value(HttpHeaders.userAgentHeader)}');
  }

  void serverLog(AlkaidServerException alkaidServerException,Level level) {
    _serverLogger.log(level, alkaidServerException.message,alkaidServerException.stackTrace);
  }

  void errorLog(Level level,dynamic message,dynamic error,StackTrace? stackTrace) {
    _errorLogger.log(level, message,error,stackTrace);
  }

}
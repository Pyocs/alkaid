import 'dart:io';
import 'alkaid_exception.dart';

class AlkaidHttpException extends AlkaidException {
  ///HTTP 响应码
  final int code;

  ///错误响应内容
  dynamic message;

  final String _content = '''
  <!DOCTYPE html>
<html>
  <head>
    <style>
      body {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        margin: 0;
      }
    </style>
  </head>
  <body>
    <h1>message</h1>
  </body>
</html>

  ''';

  String _fromContent(String message) => _content.replaceAll('message', message);

  AlkaidHttpException(this.code,{this.message}) {
    if(message is String) {
      message = _fromContent(message);
    } else if(message is File) {
      message = (message as File).readAsBytesSync();
    } else {
      message = 'ERROR!';
    }
  }


  factory AlkaidHttpException.notFound({dynamic message}) {
    message ??= r"404 Not Found";
    return AlkaidHttpException(404,message: message);
  }

  factory AlkaidHttpException.badRequest({dynamic message}) {
    message ??= r'400 Bad Request';
    return AlkaidHttpException(400,message: message);
  }

  factory AlkaidHttpException.unauthorized({dynamic message}) {
    message ??= r'400 Unauthorized';
    return AlkaidHttpException(401,message: message);
  }

  factory AlkaidHttpException.forbidden({dynamic message}) {
    message ??= r'403 Forbidden';
    return AlkaidHttpException(403,message: message);
  }

  factory AlkaidHttpException.internalServerError({dynamic message}) {
    message ??= r'500 Internal Server Error';
    return AlkaidHttpException(500,message: message);
  }

  factory AlkaidHttpException.badGateway({dynamic message}) {
    message ??= r'502 Bad Gateway';
    return AlkaidHttpException(502,message: message);
  }

  factory AlkaidHttpException.serviceUnavailable({dynamic message}) {
    message ??= r'503 Service Unavailable';
    return AlkaidHttpException(503,message: message);
  }

  factory AlkaidHttpException.notAcceptable({dynamic message}) {
    message ??= r'406 Not Acceptable';
    return AlkaidHttpException(406,message: message);
  }

  factory AlkaidHttpException.methodNotAllowed({dynamic message}) {
    message ??= r'405 Method Not Allowed';
    return AlkaidHttpException(405,message: message);
  }


  @override
  String toString() {
    return 'StatusCode:$code  message:$message';
  }
}
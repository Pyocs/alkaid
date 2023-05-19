import 'alkaid_exception.dart';
class AlkaidServerException extends AlkaidException {
  ///错误信息
  final String message;

  ///异常栈
  late final StackTrace? stackTrace;

  AlkaidServerException(this.message,{this.stackTrace});

  ///路由重复
  factory AlkaidServerException.routeDuplication({String? message,stackTrace}) {
    message ??= 'Route Duplication!';
    return AlkaidServerException(message,stackTrace: stackTrace);
  }

  ///请求方法设置错误
  factory AlkaidServerException.requestMethodError({String? message,stackTrace}) {
    message ??= 'Request Method Error';
    return AlkaidServerException(message,stackTrace: stackTrace);
  }

  ///模块weight超出范围
  factory AlkaidServerException.modulesWeightError({String? message,stackTrace}) {
    message ??= 'Modules Weight Out of Range';
    return AlkaidServerException(message,stackTrace: stackTrace);
  }

  ///向事件总线中重复添加请求
  factory AlkaidServerException.repeatAddRequest({String? message,stackTrace}) {
    message ??= 'Repeat Add HttpRequest';
    return AlkaidServerException(message,stackTrace: stackTrace);
  }

}
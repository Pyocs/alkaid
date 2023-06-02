import 'package:redis/redis.dart';

class AlkaidRedisCommand {

  final Command _command;

  bool _transaction = false;
  bool get transaction => _transaction;

  AlkaidRedisCommand(this._command);

  //事务
  ///开启事务
  Future<String?> multi()  async {
    if(!_transaction) {
      _transaction = true;
      return await _command.send_object(['multi']);
    }
    return null;
  }

  ///提交事务
  Future<List?> exec()  async {
    if(_transaction) {
      _transaction = false;
      return await _command.send_object(['exec']);
    }
    return null;
  }

  //发布订阅
  ///订阅频道
  Future<dynamic> subScribe(List<String> channels) async {
    return await _command.send_object(['subscribe',...channels]);
  }

  ///取消订阅
  Future<dynamic> unSubScribe(List<String> channels) async {
    return await _command.send_object(['unsubscribe',...channels]);
  }

  ///给频道发送消息
  Future<dynamic> publish(String channel ,String message) async {
    return await _command.send_object(['publish',channel,message]);
  }



  //键的过期时间
  //排序

}
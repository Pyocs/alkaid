import 'package:redis/redis.dart';

class AlkaidRedisCommandMap {
  final Command _command;
  Command get command => _command;
  AlkaidRedisCommandMap(this._command);

  ///设置散列对象的一个属性和值
  Future<bool> hSet(String key,String field,dynamic value) async {
     if((await _command.send_object(['hset',key,field,value])).toString() == '1') {
       return true;
     }
     return false;
  }

  ///获取散列对象中指定属性的值
  ///没有返回null
  Future<dynamic> hGet(String key,String field) async {
    return await _command.send_object(['hget',key,field]);
  }

  ///获取散列对象中所有属性和对应的值
  Future<List> hGetAll(String key) async {
    return await _command.send_object(['hgetall',key]);
  }

  ///删除散列对象中指定的属性
  Future<bool> hDel(String key,List<String> fields) async {
    if((await _command.send_object(['hdel',key,...fields])).toString() == '1') {
      return true;
    }
    return false;
  }

  Future<bool> del(String key) async {
    if((await _command.send_object(['del',key])).toString() == '1') {
      return true;
    }
    return false;
  }

  ///从散列中获取一个或多个键的值
  Future<List> hMGet(String key,List<String> fields) async {
    return await _command.send_object(['hmget',key,...fields]);
  }

  ///为散列中的一个或多个键设置值
  ///hmset map key value [key value...]
  Future<bool> hMSet(String key,List<String> values) async {
    if((await _command.send_object(['hmset',key,...values])).toString() == 'OK') {
      return true;
    }
    return false;
  }

  ///返回散列键值对数量
  Future<int> hLen(String key) async {
    return await _command.send_object(['hlen',key]);
  }

  ///检查给定键是否存在
  Future<bool> hExists(String key,String field) async {
    if((await _command.send_object(['hexists',key,field])).toString() == '1') {
      return true;
    }
    return false;
  }

  ///获取所有键
  Future<List> hKeys(String key) async {
    return await _command.send_object(['hkeys',key]);
  }

  ///获取所有值
  Future<List> hVals(String key) async {
    return await _command.send_object(['hvals',key]);
  }

  ///将值加上整数
  Future<int> hIncrBy(String key,String field,int increment) async {
    return await _command.send_object(['hincrby',key,field,increment]);
  }

  Future<double> hIncrByFloat(String key,String field,String increment) async {
    return double.parse(await _command.send_object(['hincrbyfloat',key,field,increment]));
  }
}
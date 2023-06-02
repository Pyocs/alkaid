import 'package:redis/redis.dart';

///对常用Redis命令的封装(字符串)
class AlkaidRedisCommandString {
  final Command _command;
  Command get command => _command;
  AlkaidRedisCommandString(this._command);


  //字符串命令

  ///获取键的值
  get(String key) async {
    return await _command.send_object(['get',key]);
  }

  ///设置键的值
  Future<bool> set(String key,dynamic value) async {
    if((await _command.send_object(['set',key,value.toString()])).toString() == 'OK') {
      return true;
    }
    return false;
  }

  ///删除键的值
  Future<bool> del(String key) async {
    if((await _command.send_object(['del',key])).toString() == '1') {
      return true;
    } else {
      return false;
    }
  }

  ///自增 如果不存在，则初始化为0
  Future<String> incr(String key) async {
    return await _command.send_object(['incr',key]);
  }

  ///将键值加上
  Future<int> incrBy(String key,int value) async {
    return await _command.send_object(['incrby',key,value]);
  }

  ///自减
  Future<int> decr(String key) async {
    return await _command.send_object(['decr',key]);
  }

  ///将键值减去
  Future<int> decrBy(String key,int value) async {
    return await _command.send_object(['decrby',key,value]);
  }

  ///将键值加上float
   Future<double> incrByFloat(String key,String value) async {
    return double.parse( await _command.send_object(['incrbyfloat',key,value]));
  }

  ///将字符串追加到末尾
  ///返回字符串长度
  Future<int> append(String key,String value) async {
    return await _command.send_object(['append',key,value]);
  }

  ///获取指定范围的字符
  Future<String> getRange(String key,int start,int end) async {
    return await _command.send_object(['getrange',key,start,end]);
  }

  /// 从start开始的字符设置成value
  ///返回长度
  Future<int> setRange(String key,int start, String value) async {
    return await _command.send_object(['setrange',key,start,value]);
  }

  ///返回offset的数(0 or 1),将String.codeUnits
  Future<int> getBit(String key,int offset) async {
    return await _command.send_object(['getbit',key,offset]);
  }

  ///设置值 (0 or 1)
  Future<int> setBit(String key,int offset,int value) async {
    return await _command.send_object(['setbit',key,offset,value]);
  }

  ///统计二进制中1的数量
  Future<int> bitCount(String key,int start,int end ) async {
    return await _command.send_object(['bitcount',key,start,end]);
  }

  ///对一个或多个二进制字符串进行 与 或 非 异或操作
  ///AND OR XOR
  bitTop(String operation,List<String> dest,String resultKey) async {
    return await _command.send_object(['bittop',operation,...dest,resultKey]);
  }

}


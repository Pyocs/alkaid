///列表
import 'package:redis/redis.dart';

class AlkaidRedisCommandList {
  final Command _command;
  Command get command => _command;
  AlkaidRedisCommandList(this._command);

  ///推入列表右端
  ///返回列表总长度
  Future<int> rPush(String key ,List value) async {
    return await _command.send_object(['rpush',key,...value]);
  }

  ///推入列表左端
  ///返回列表总长度
  Future<int> lPush(String key ,List value) async {
    return await _command.send_object(['lpush',key,...value]);
  }

  ///删除列表
  Future<bool> del(String key) async {
    if((await _command.send_object(['del',key])).toString() == '1') {
      return true;
    }
    return false;
  }

  ///获取给定范围所有值
  Future<List> lRange(String key,int start,int end) async {
    return  await _command.send_object(['lrange',key,start,end]);
  }

  ///获取给定位置上的值
  lIndex(String key,int index) async {
    return await _command.send_object(['lindex',key,index]);
  }

  ///从左端弹出一个值
  ///返回删除的值，如果为空返回null
  lPop(String key) async {
    return await _command.send_object(['lpop',key]);
  }


  ///从右端弹出一个值
  ///返回删除的值，如果为空返回null
  rPop(String key) async {
    return await _command.send_object(['rpop',key]);
  }

  ///对列表裁剪，只保留从start~end,他们两个也会保留
  ///start:1 end:0 删除全部元素
  Future<bool> lTrim(String key,int start,int end) async {
    if((await _command.send_object(['ltrim',key,start,end])).toString() == 'OK') {
      return true;
    }
    return false;
  }

  ///从第一个非空列表中弹出最左端元素，如果为空，则阻塞timeout,如果阻塞时间结束还没有元素，则返回一个空数组，如果有元素，返回弹出的元素
  ///timeout单位为秒
  ///如果有值，返回 list,3.14 列表名：被删除的值
  ///如果没有值，返回null
  Future<List> bLPop(List<String> keys,int timeout) async {
    return await _command.send_object(['blpop',...keys,timeout]);
  }

  ///从第一个非空列表中弹出最右端元素，如果为空，则阻塞timeout,如果阻塞时间结束还没有元素，则返回一个空数组，如果有元素，返回弹出的元素
  ///timeout单位为秒
  ///如果有值，返回 list,3.14 列表名：被删除的值
  ///如果没有值，返回null
  Future<List> bRPop(List<String> keys,int timeout) async {
    return await _command.send_object(['brpop',...keys,timeout]);
  }

  ///从source-key右边弹出元素，推入dest-key左边，并返回这个元素
  rPopLPush(String sourceKey,String destKey) async {
    return await _command.send_object(['rpoplpush',sourceKey,destKey]);
  }

  ///从source-key右边弹出元素，推入dest-key左边，并返回这个元素
  ///如果为空会阻塞timeout 单位s
  bRPopLPush(String sourceKey,String destKey,int timeout) async {
    return await _command.send_object(['brpoplpush',sourceKey,destKey,timeout]);
  }


}
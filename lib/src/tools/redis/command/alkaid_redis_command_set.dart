import 'package:alkaid/interact/gpt/generate_handler_method.dart';
import 'package:redis/redis.dart';
class AlkaidRedisCommandSet {
  final Command _command;
  Command get command => _command;
  AlkaidRedisCommandSet(this._command);

  ///将给定元素添加到集合
  ///返回成功添加的个数
  Future<int> sAdd(String key,List members) async {
    return await _command.send_object(['sadd',key,...members]);
  }

  ///返回set集合中所有元素
  Future<List> sMembers(String key) async {
    return await _command.send_object(['smembers',key]);
  }

  ///检查给定元素是否存在集合中
  Future<bool> sIsMember(String key,dynamic member) async {
    if((await _command.send_object(['sismember',key,member])).toString() == '1') {
      return true;
    }
    return false;
  }

  ///如果给定元素存在集合中，则移除它
  ///返回成功删除元素的数量
  Future<int> sRem(String key,List members) async {
    return await _command.send_object(['srem',key,...members]);
  }

  ///返回该集合元素的数量
  Future<int> sCard(String key) async {
    return await _command.send_object(['scard',key]);
  }

  ///从集合随机返回一个或多个元素，当count为正数是返回元素不会重复，count为负数时返回元素可能会重复
  Future<List> sRandMember(String key,int count) async {
    return await _command.send_object(['srandmember',key,count]);
  }

  ///随机移除一个元素并返回(或多个)
  sPop(String key,{int count = 1}) async {
    return await _command.send_object(['spop',key,count]);
  }

  ///如果source-key包含item 则从source-key 中移除item并添加到dest-key中，如果移除成功返回1,否则0
  Future<bool> sMove(String sourceKey,String destKey,dynamic item) async {
    if((await _command.send_object(['smove',sourceKey,destKey,item])).toString() == '1') {
      return true;
    }
    return false;
  }

  ///返回那些存在第一个集合但不存在其他集合的元素
  Future<List> sDiff(List<String> keys) async {
    return await _command.send_object(['sdiff',...keys]);
  }

  ///返回那些存在第一个集合但不存在其他集合的元素并存在dest-key中
  sDiffStore(String destKey,List<String> keys) async {
    return await _command.send_object(['sdiffstore',destKey,...keys]);
  }

  ///返回那些同时存在多个集合的元素
  Future<List> sInter(List<String> keys) async {
    return await _command.send_object(['sinter',...keys]);
  }

  ///返回那些同时存在多个集合的元素并存入dest-key
  sInterStore(String destKey,List<String> keys) async {
    return await _command.send_object(['sinterstore',destKey,...keys]);
  }

  ///至少存在一个集合中的元素
  Future<List> sUnion(List<String> keys) async {
    return await _command.send_object(['sunion',...keys]);
  }

  ///将那些至少存在一个集合中的元素存入dest-key中
  sUnionStore(String destKey,List<String> keys) async {
    return await _command.send_object(['sunionstore',destKey,...keys]);
  }

}
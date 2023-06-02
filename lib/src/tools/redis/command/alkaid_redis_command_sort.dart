import 'package:redis/redis.dart';

class AlkaidRedisCommandSort {
  final Command _command;

  Command get command => _command;

  AlkaidRedisCommandSort(this._command);

  ///添加数据
  ///score 为int 或 double
  Future<bool> zAdd(String key,dynamic score,String member) async {
    if((await _command.send_object(['zadd',key,score.toString(),member])).toString() == '1') {
      return true;
    }
    return false;
  }

  ///从有序集合中删除给定成员，返回成功数量
  Future<int> zRem(String key,List<String> members) async {
    return await _command.send_object(['zrem',key,...members]);
  }

  ///返回成员member的分值
  ///返回值类型为int 或 double
  Future<dynamic> zScore(String key,String member) async {
    return await _command.send_object(['zscore',key,member]);
  }

  ///返回集合数量
  Future<int> zCard(String key) async {
    return await _command.send_object(['zcard',key]);
  }

  ///返回分值介于min和max的成员数量
  Future<int> zCount(String key,dynamic min,dynamic max) async {
    return await _command.send_object(['zcount',key,min.toString(),max.toString()]);
  }

  ///根据有序排列中的位置，从中取出多个元素
  ///从低到高
  Future<List> zRange(String key,int start,int stop,{bool withScores = false}) async {
    if(withScores) {
      return await _command.send_object(['zrange',key,start,stop,'withscores']);
    } else {
      return await _command.send_object(['zrange',key,start,stop]);
    }
  }

  ///返回成员member在有序集合的排名
  ///没有元素返回null
  zRank(String key,String member) async {
    return await _command.send_object(['zrank',key,member]);
  }

  ///获取有序集合给定分值范围内的所有元素
  Future<List> zRangeByScore(String key,dynamic min,dynamic max,{bool withScores = false}) async {
    if(!withScores) {
      return await _command.send_object(['zrangebyscore',key,min.toString(),max.toString()]);
    } else {
      return await _command.send_object(['zrangebyscore',key,min.toString(),max.toString(),'withscores']);
    }
  }

  ///将指定成员分值增加inc,如果不存在则设置一个新的
  Future<dynamic> zIncrby(String key,dynamic increment,String member) async {
    return await _command.send_object(['zincrby',key,increment.toString(),member]);
  }

  ///根据排名删除元素
  ///返回删除成功数量
  ///0 -1 删除全部元素
  Future<int> zRemRangeByRank(String key,int start,int end) async {
    return await _command.send_object(['zremrangebyrank',key,start,end]);
  }

  ///根据有序排列中的位置，从中取出多个元素
  ///从高到低
  Future<List> zRevRange(String key,int start,int stop,{bool withScores = false}) async {
    if(withScores) {
      return await _command.send_object(['zrevrange',key,start,stop,'withscores']);
    } else {
      return await _command.send_object(['zrevrange',key,start,stop]);
    }
  }



}
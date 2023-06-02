import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alkaid/src/tools/redis/command/alkaid_redis_command.dart';
import 'package:alkaid/src/tools/redis/command/alkaid_redis_command_string.dart';
import 'package:redis/redis.dart';

void main() async {
  Command command  = await RedisConnection().connect('192.168.1.127', 6379);
  AlkaidRedisCommand alkaidRedisCommand = AlkaidRedisCommand(command);
  AlkaidRedisCommandString string = AlkaidRedisCommandString(command);
  //开启事务
  print(await alkaidRedisCommand.multi());
   string.set('num', 1);
   string.incr('num');
   string.get('num');
  //提交事务
  print(await alkaidRedisCommand.exec());
  
  PubSub pubSub = PubSub(command);
  pubSub.subscribe(['channel']);
  pubSub.getStream().listen((event) {
    print(event);
  });
  await Future.delayed(Duration(minutes: 1));
  command.get_connection().close();
  // test();
}


void test() async {
  Socket socket = await Socket.connect('192.168.1.127', 6379);
  socket.listen((event) {
    print(String.fromCharCodes(event));
  });

  // socket.write('zrange sort 0 -1 \n get key\n');
  socket.write('subscribe channel\n');

  
  await Future.delayed(Duration(minutes: 3));
  socket.write('unsubscribe channel\n');
  await socket.close();
}
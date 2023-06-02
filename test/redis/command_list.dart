import 'dart:js_interop';

import 'package:alkaid/src/tools/redis/command/alkaid_redis_command_list.dart';
import 'package:redis/redis.dart';

void main() async {
  Command command = await RedisConnection().connect('192.168.1.127', 6379);
  AlkaidRedisCommandList commandList = AlkaidRedisCommandList(command);

  print(await commandList.del('list'));
  print(await commandList.rPush('list', [2,'hello','3.14']));
  print(await commandList.rPush('list', [3]));
  print(await commandList.lRange('list', 0, -1));
  print(await commandList.lIndex('list', 0));
  print(await commandList.lPop('list'));
  print(await commandList.lPop('list'));
  // print(await commandList.lTrim('list', 1, 0));
  // print(await commandList.lTrim('list', 0, 3));
  print(await commandList.bLPop(['list'], 3));


  command.get_connection().close();
}
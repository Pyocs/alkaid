import 'package:alkaid/src/tools/redis/command/alkaid_redis_command_set.dart';
import 'package:redis/redis.dart';

void main()  async {
  Command command = await RedisConnection().connect('192.168.1.127', 6379);
  AlkaidRedisCommandSet set = AlkaidRedisCommandSet(command);

  print(await set.sAdd('set', [1,2,'hello','haha']));
  print(await set.sAdd('set', [2,4]));
  print(await set.sMembers('set'));
  print(await set.sIsMember('set', 1));
  print(await set.sRem('set', [1,2]));
  print(await set.sCard('set'));
  print(await set.sRandMember('set', 1));
  print(await set.sPop('set'));
  print(await set.sMove('set', 'set2', 4));
  command.get_connection().close();
}
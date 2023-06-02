import 'package:alkaid/src/tools/redis/command/alkaid_redis_command_map.dart';
import 'package:redis/redis.dart';

void main() async {
  Command command =  await RedisConnection().connect('192.168.1.127', 6379);
  AlkaidRedisCommandMap map = AlkaidRedisCommandMap(command);

  print(await map.hSet('map', 'key', 'value'));
  print(await map.hGet('map', 'ke'));
  print(await map.hSet('map', 'he', 'wo'));
  print(await map.hGetAll('map'));
  print(await map.hDel('map', ['hello']));
  print(await map.hMGet('map', ['key','ke']));
  print(await map.hMSet('map', ['hello','world']));
  print(await map.hLen('a'));
  print(await map.hExists('map', 'ky'));
  print(await map.hKeys('map'));
  print(await map.hVals('map'));
  await map.hSet('map', 'num', 1);
  print(await map.hIncrBy('map', 'num', 3));
  await map.hSet('map', 'double', '3.14');
  print(await map.hIncrByFloat('map', 'double', '3.25'));
  command.get_connection().close();

}
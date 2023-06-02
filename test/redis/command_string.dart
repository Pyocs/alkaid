
import 'package:alkaid/src/tools/redis/command/alkaid_redis_command_string.dart';
import 'package:redis/redis.dart';

void main() async {
   Command command  = await  RedisConnection().connect('192.168.1.127', 6379);
    AlkaidRedisCommandString alkaidRedisCommand = AlkaidRedisCommandString(command);

    print(await alkaidRedisCommand.set('key', '1'));
    print(await alkaidRedisCommand.get('key'));
    // print(await alkaidRedisCommand.del('key'));
    // print(await alkaidRedisCommand.incr('key'));
    print(await alkaidRedisCommand.incrBy('key', 12));
    print(await alkaidRedisCommand.incrByFloat('key', '3.14'));
    await alkaidRedisCommand.set('test', 'hello');
    print(await alkaidRedisCommand.get('test'));
    print(await alkaidRedisCommand.append('test', ' world!'));
    print(await alkaidRedisCommand.getRange('test', 1, 5));
    print(await alkaidRedisCommand.setRange('test', 1, 'haha'));
    print(await alkaidRedisCommand.getRange('test', 0, -1));
    print(await alkaidRedisCommand.getBit('test', 2));
    print(await alkaidRedisCommand.setBit('test', 2, 0));
    print(await alkaidRedisCommand.get('test'));
    print(await alkaidRedisCommand.bitCount('test', 0, -1));
    command.get_connection().close();
}
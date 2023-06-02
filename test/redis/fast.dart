import 'dart:io';

import 'package:redis/redis.dart';

void main() async {
  const int N = 200000;
  int start;
  final conn = RedisConnection();
  conn.connect('192.168.1.127',6379).then((Command command){
    print("test started, please wait ...");
    start = DateTime.now().millisecondsSinceEpoch;
    // command.pipe_start();
    command.send_object(["SET","test","0"]);
    for(int i=1;i<=N;i++){
      command.send_object(["INCR","test"])
          .then((v){
        if(i != v)
          throw("wrong received value, we got $v");
      });
    }
    //last command will be executed and then processed last
    command.send_object(["GET","test"]).then((v){
      print(v);
      double diff = (new DateTime.now().millisecondsSinceEpoch - start)/1000.0;
      double perf = N/diff;
      print("$N operations done in $diff s\nperformance $perf/s");
    });
    command.pipe_end();
  });
}


void pipe() async  {
  Command command = await RedisConnection().connect('192.168.1.127', 6379);

  final pipeline = <String>[];

  pipeline.add('SET key1 value1');
  pipeline.add('SET key2 value2');
  pipeline.add('GET key1');
  pipeline.add('GET key2');


}
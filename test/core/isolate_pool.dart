import 'dart:async';

import 'package:alkaid/src/core/isolate_pool.dart';

Future<void> main() async {
  IsolatePool isolatePool = IsolatePool.getPool(1, 2);


  await isolatePool.submitRepeatTask((message) {
    int result = 0;
    for(int i = 0 ; i < message ; i++) {
      result += i;
    }
    return result;
  },'add',keepConnection: false);

  for(int i = 0 ; i < 10 ; i++) {
    isolatePool.runTask('add', 10000).then((value) {
      print('$i  $value');
    });
  }

  await Future.delayed(Duration(milliseconds: 20));
  isolatePool.close();

   /*

   isolatePool.runOnceTask((message) {
    int result = 0;
    for(int i = 0 ; i < message ; i++) {
      result += i;
    }
    return result;
  }, 10000).then(print);

   isolatePool.submitNotParamOnce(() {
     int result = 0;
     for(int i = 0 ; i < 10086 ; i++) {
       result += i;
     }
     return result;
   }).then(print);

   */
}
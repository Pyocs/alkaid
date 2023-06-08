import 'dart:async';

import 'package:alkaid/orm.dart';
import 'package:alkaid/src/orm/alkaid_mysql_pool.dart';
 DatabaseConfig  databaseConfig = DatabaseConfig(name: 'mysql',
    host: '192.168.1.127', port: 3306, user: 'root', password: 'tan+82698',databaseName: 'mybatis',secure: false);
void main() async {
  AlkaidMySqlPool alkaidMySqlPool = AlkaidMySqlPool(databaseConfig,minCapacity: 100,maxCapacity: 1000,timeout: Duration(seconds: 10));

  /*
  var p1 = await alkaidMySqlPool.getConnection();
  print('获取第一个连接:${p1.toString()}\n${p1.hashCode}\n${DateTime.now()}');
  print('\n');

  Timer(Duration(seconds: 15),() {
    alkaidMySqlPool.dispose(p1);
  });

  var p2 = await alkaidMySqlPool.getConnection();
  print('获取第二个连接:${p2.toString()}\n${p2.hashCode}\n${DateTime.now()}');
  print('\n');
  var p3 = await alkaidMySqlPool.getConnection();
  print('获取第三个连接:${p3.toString()}\n${p3.hashCode}\n${DateTime.now()}');
  print('\n');

  Timer(Duration(seconds: 15),() {
    alkaidMySqlPool.dispose(p2);
  });

  Timer(Duration(seconds: 15),() {
    alkaidMySqlPool.dispose(p3);
  });

  Timer(Duration(seconds: 60),() {
    alkaidMySqlPool.close();
  });

   */
}
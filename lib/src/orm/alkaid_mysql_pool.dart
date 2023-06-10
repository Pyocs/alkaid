import 'dart:async';
import 'dart:collection';
import 'config/database_config.dart';
import 'package:mysql_client/mysql_client.dart';
///Mysql连接池
class AlkaidMySqlPool {
  //新创建的连接可以放入队列的末尾，而从连接池中获取连接时可以从队列的头部取出
  //空闲的连接
  final Queue<MySQLConnection> _pool = Queue<MySQLConnection>();
  //已经使用的连接
  final Queue<MySQLConnection> _busyPool = Queue();
  //等待队列
  final Queue<Completer<MySQLConnection>> _waitQueue = Queue();
  final DatabaseConfig _databaseConfig;
  //池中允许的最小连接数.连接池中始终保持的最小连接数量
  late final int _minCapacity;
  //池中允许的最大连技数.连接池中允许存在的最大连接数量
  late final int _maxCapacity;
  late final Timer? _timer;
  late final Timer? _keepTimer;

  //超时时间，如果连接在超过time后还未使用，则关闭连接,如果为null,则永不超时
  late final Duration? _timeout;
  //保持连接,避免连接池中的连接长时间未活动被mysql清除
  late final Duration? _keepConnection;
  int get minCapacity => _minCapacity;
  int get maxCapacity => _maxCapacity;
  //已经使用的连接数
  int identityBusyCapacity = 0;
  //空闲的连接数
  int get idleCapacity => _pool.length;
  Duration? get timeout => _timeout;

  AlkaidMySqlPool(this._databaseConfig,{
    int? minCapacity,
    int? maxCapacity,
    Duration? timeout,
    Duration? keepConnection
  }) {
    _minCapacity = minCapacity ?? 1;
    _maxCapacity = maxCapacity ?? 10;
    _timeout = timeout ?? Duration(seconds: 60);  //默认超时时间60s
    _keepConnection = keepConnection;
    
  }


  Future<void> init() async {


    for(int i = 0 ; i < _minCapacity ; i++) {
      MySQLConnection mySQLConnection = await MySQLConnection.createConnection(host: _databaseConfig.host,
            port: _databaseConfig.port,
            userName: _databaseConfig.user,
            password: _databaseConfig.password,
            databaseName: _databaseConfig.databaseName,
            secure: _databaseConfig.secure);
      await mySQLConnection.connect();
      _pool.add(mySQLConnection);
    }
    if(_timeout != null) {
      _timer = Timer.periodic(_timeout!, (timer) {
        //每个timeout删除队头的连接
        //是否立即清除？如果连接处于正常状态，则不清除
        //如果处于异常状态，则清除
        if(idleCapacity > _minCapacity) {
          _pool.removeFirst().close();
        }
      });
    }

    if(_keepConnection != null) {
      //每个keepConnection将空闲队列中的连接发送一次select 1
      _keepTimer = Timer.periodic(_keepConnection!, (timer) {
        for(var connection in _pool) {
          connection.execute('select 1');
        }
      });
    }


  }

  ///从池中获取一个连接
  Future<MySQLConnection> getConnection() async {
    if(_pool.isNotEmpty) {
      MySQLConnection mySQLConnection = _pool.removeFirst();
      _busyPool.add(mySQLConnection);
      identityBusyCapacity++;
      return mySQLConnection;
    } else {
      //如果已经使用的连接数未达到最大连接数，则新建一个连接
      if(identityBusyCapacity < maxCapacity) {
        //此处有一个bug,如果调用函数没有使用await,则执行完下面函数会立即返回，_busyPool.length没有改变
        //但后续会添加到_busyPool中，如果有另一个线程也执行到这里，会导致busyCapacity出现幻读
        identityBusyCapacity++;
        MySQLConnection mySQLConnection = await MySQLConnection.createConnection(host: _databaseConfig.host,
            port: _databaseConfig.port,
            userName: _databaseConfig.user,
            password: _databaseConfig.password,
            databaseName: _databaseConfig.databaseName,
            secure: _databaseConfig.secure);
        _busyPool.add(mySQLConnection);
        await mySQLConnection.connect();
        return mySQLConnection;
      } else {
        //等待其他空闲的连接
        Completer<MySQLConnection> completer = Completer();
        _waitQueue.addLast(completer);
        return completer.future;
      }
    }
  }

  ///释放连接
  void dispose(MySQLConnection mySQLConnection) {

    if(_busyPool.remove(mySQLConnection)) {
      identityBusyCapacity--;
      _pool.addLast(mySQLConnection);

      if(_waitQueue.isNotEmpty) {
        Completer<MySQLConnection> completer = _waitQueue.removeFirst();
        _pool.remove(mySQLConnection);
        identityBusyCapacity++;
        _busyPool.add(mySQLConnection);
        completer.complete(mySQLConnection);
      }

    }

  }

  void close() async {

    //等待任务完成
    //每隔1s检查任务是否完成，如果10s内还没有完成，则强制关闭
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if(_busyPool.isEmpty) {
        //关闭所有连接
        for(int i = 0 ; i < _pool.length ; i++) {
          if(_pool.elementAt(i).connected) {
            await _pool.elementAt(i).close();
          }
        }
        timer.cancel();
        _pool.clear();
        _busyPool.clear();
      } else if(timer.tick >= 10 ) {
        for(int i = 0 ; i < _pool.length ; i++) {
          if(_pool.elementAt(i).connected) {
            await _pool.elementAt(i).close();
          }
        }

        for(int i = 0 ; i < _busyPool.length ; i++) {
          _busyPool.elementAt(i).close();
        }
        timer.cancel();
        _pool.clear();
        _busyPool.clear();
      }
    });

    _waitQueue.clear();
    if(_timer != null) {
      _timer!.cancel();
    }
    if(_keepTimer != null) {
      _keepTimer!.cancel();
    }

  }
}
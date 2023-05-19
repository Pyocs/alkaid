import 'dart:collection';

import 'package:mysql_client/mysql_client.dart';

///缓存PreparedStmt
///根据sql语句
class PreparedStmtCache {
  late final HashMap<int,PreparedStmt> _cache;

  PreparedStmtCache() {
    _cache = HashMap();
  }

  void addValue(String sql,PreparedStmt preparedStmt) {
    _cache.addEntries({sql.hashCode:preparedStmt}.entries);
  }

  PreparedStmt? deleteValue(String sql) {
    return _cache.remove(sql.hashCode);
  }

  PreparedStmt? getValue(String sql) {
    return _cache[sql.hashCode];
  }

  Future<void> clear()  async{
    for (var element in _cache.values) {
      await element.deallocate();
    }
    _cache.clear();
  }

  @override
  String toString() {
    return _cache.toString();
  }

}
import 'dart:collection';

import 'package:alkaid/src/modules/cache/store/cache_store.dart';

class SortMapCacheStore<K,V> implements CacheStore<K,V> {
  late final SplayTreeMap<K,V> _map;
  SortMapCacheStore([int Function(K,K)? compute]) : _map = SplayTreeMap(compute);

  @override
  void add(k, v) {
    _map[k] = v;
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  bool contains(k) {
    return _map.containsKey(k);
  }

  @override
  get(k) {
    return _map[k];
  }

  @override
  int getSize() {
    return _map.length;
  }

  @override
  bool isEmpty() {
    return _map.isEmpty;
  }

  @override
  void remove(k) {
    _map.remove(k);
  }

  @override
  replace(k, v) {
    var value = _map[k];
    _map[k] = v;
    if(value == null) {
      return value;
    }
    return v;
  }

  @override
  // TODO: implement keys
  List<K> get keys => _map.keys.toList();

}
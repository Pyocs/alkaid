import 'package:alkaid/src/modules/cache/store/cache_store.dart';

///缓存算法
abstract class CacheAlgorithm<K,V> {
  final CacheStore _cacheStore;
  CacheStore get cacheStore => _cacheStore;
  CacheAlgorithm(this._cacheStore);

  void add(K k,V v);
  dynamic get(K k);
  dynamic replace(K k,V v);
  void remove(K k);
  bool contains(K k);
  ///清空缓存
  void clear();
  int getSize();
  bool isEmpty();
  ///按照算法清除过期缓存
  void eliminate();
}
///存放缓存的方式
abstract class CacheStore<K,V> {
  void add(K k,V v);
  dynamic get(K k);
  dynamic replace(K k,V v);
  void remove(K k);
  bool contains(K k);
  void clear();
  int getSize();
  bool isEmpty();
  List<K> get keys;
}
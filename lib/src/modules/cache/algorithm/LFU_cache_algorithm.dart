import 'package:alkaid/src/modules/cache/algorithm/cache_algorithm.dart';

///LFU(Least Frequently Used): 最近最不常用算法,根据数据的历史访问频率来淘汰数据
/*
在缓存中查找客户端需要访问的数据
如果缓存命中，则将访问的数据从队列中取出，并将数据对应的频率计数加1，然后将其放到频率相同的数据队列的头部，比如原来是A(10)->B(9)->C(9)->D(8),D被访问后，它的time变成了9，这时它被提到A和B之间，而不是继续在C后面
如果没有命中，表示缓存穿透，将需要访问的数据从磁盘中取出，加入到缓存队列的尾部，记频率为1，这里也是加入到同为1的那一级的最前面
如果此时缓存满了，则需要先置换出去一个数据，淘汰队列尾部频率最小的数据，然后再在队列尾部加入新数据。
 */
class LFUCacheAlgorithm<K,V> extends CacheAlgorithm<K,V> {
  final int _capacity;
  int get _length => cacheStore.getSize();
  LFUCacheAlgorithm(super.cacheStore,this._capacity);

  @override
  void add(k, v) {
    if(_length < _capacity) {
      cacheStore.add(k, v);
    } else {
      //将使用频率最小的数据置换出去
      var last = cacheStore.keys.last as LFUCacheMeta;
      remove(last.key);
      cacheStore.add(k, v);
    }
  }

  @override
  void clear() {
    cacheStore.clear();
  }

  @override
  bool contains(k) {
    return cacheStore.contains(k);
  }

  @override
  void eliminate() {
    // TODO: implement eliminate
  }

  @override
  get(k) {
    var value = cacheStore.get(k);
    if(value == null) {
      return null;
    }
    k = cacheStore.keys.firstWhere((element) => element == k);
    cacheStore.remove(k);
    (k as LFUCacheMeta).widget++;
    cacheStore.add(k, value);
    return value;
  }

  @override
  int getSize() {
    return _length;
  }

  @override
  bool isEmpty() {
    return cacheStore.isEmpty();
  }

  @override
  void remove(k) {
    cacheStore.remove(k);
  }

  @override
  replace(k, v) {
    return cacheStore.replace(k, v);
  }


}

class LFUCacheMeta<K>{
  int widget;
  K key;

  LFUCacheMeta(this.widget,this.key);
}
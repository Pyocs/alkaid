import 'dart:collection';
///存储与AI对话的结果
///测试从store里取出
///如果写入到文件中则会删除缓存
class HandlerStore {
  int _i = 1;
  final HashMap<int,String> _store = HashMap();

  static final  HandlerStore handlerStore = HandlerStore();

  HashMap<int,String> get store => _store ;


  void add(String result) {
    _store.addEntries({_i++:result}.entries);
  }

  void remove(int id) {
    _store.remove(id);
  }

  List<String> getAll() {
    return _store.values.toList();
  }

  String? get(int id) {
    return _store[id];
  }

  void removeAll() {
    _store.clear();
  }

  String? getFirst() {
    if(_i == 1) {
      return null;
    }
    return _store[1];
  }

  String? getLast() {
    if(_i == 1) {
      return null;
    }
    return _store[_i - 1];
  }

  bool replace(int id ,String message) {
    if(id >= _i) {
      return false;
    }
    _store[id] = message;
    return true;
  }
}
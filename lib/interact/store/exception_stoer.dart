import 'dart:collection';

///存储异样信息

class ExceptionStore {
  static final ExceptionStore exceptionStore = ExceptionStore._();

  // handler_1:exception
  final HashMap<String,String> _store = HashMap();

  HashMap<String,String> get store => _store;

  ExceptionStore._();


  void add(String name,int id,String exception) {
    if(_store['${name}_$id'] == null) {
      _store['${name}_$id'] = exception;
    } else {
      _store['${name}_$id'] = "${_store['${name}_$id']}$exception";
    }
  }

  void remove(String name,int id) {
    _store.remove('${name}_$id');
  }

  String? get(String name,int id) {
    return _store['${name}_$id'];
  }

  Map<int,String> getHandler() {
    Map<int,String> temp = {};


    _store.forEach((key, value) {
      if(key.split('_')[0] == 'handler') {
        temp[int.parse(key.split('_')[1])] = value;
      }
    });
    return temp;
  }

  void clear() {
    _store.clear();
  }

  void clearHandler() {
    List<String> temp = [];
    _store.forEach((key, value) {
      if(key.split('_')[0] == 'handler') {
        temp.add(key);
      }
    });

    for(var ele in temp) {
      _store.remove(ele);
    }
  }
}
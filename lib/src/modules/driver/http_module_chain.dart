import '../http_module.dart';

///模块链，用于存储、添加、删除、获取模块
class HttpModuleChain {
  final List<HttpModules> _chain = List.empty(growable: true);

  HttpModuleChain([List<HttpModules>? list]) {
    if(list != null) {
      addAll(list);
    }
  }

  List<HttpModules> get chain => _chain;

  int _sort(HttpModules first,HttpModules second) {
    return first.weight - second.weight;
  }

  ///添加一个模块
  void add(HttpModules httpModules) {
    _chain.add(httpModules);
    _chain.sort(_sort);
  }

  ///添加全部模块
  void addAll(List<HttpModules> list) {
    _chain.addAll(list);
    _chain.sort(_sort);
  }

  ///根据名称删除模块
  void delete(String name) {
    _chain.removeWhere((element) => element.name == name);
    _chain.sort(_sort);
  }

  ///根据权重值删除去全部模块
  void deleteAll(int weight) {
    _chain.removeWhere((element) => element.weight == weight);
    _chain.sort(_sort);
  }

  ///获取一个模块,传入当前模块的weight,如果传入负数,则返回第一个模块
  HttpModules? get(int weight,String name) {
    if(weight < 0) {
      if(_chain.isNotEmpty) {
        return _chain.first;
      } else {
        return null;
      }
    }
    for(int i = 0 ; i < _chain.length ; i++) {
      if(_chain[i].weight >= weight && _chain[i].name != name) {
        return _chain[i];
      }
    }
    return null;
  }

  ///返回下一个模块
  HttpModules? next(HttpModules httpModules) {
    for(int i = 0 ; i< _chain.length ; i++) {
      if(_chain[i] == httpModules) {
        if(i + 1 < _chain.length) {
          return _chain[i + 1];
        }
      }
    }
    return null;
  }

  ///获取前一个模块
  HttpModules? previous(HttpModules httpModules) {
    for(int i = 0 ; i < _chain.length ; i++) {
      if(_chain[i].weight <= httpModules.weight && i+1 < _chain.length
          && _chain[i+1] == httpModules && _chain[i].name != httpModules.name) {
        return _chain[i];
      }
    }
    return null;
  }


  ///二分查找该模块在列表中的索引
  ///如果模块数量多建议使用
  int _binarySearch(HttpModules httpModules) {
    int left = 0;
    int right = _chain.length - 1;

    while(left <= right) {
      int mid = (( left + right ) ~/ 2);

      if(_chain[mid] == httpModules) {
        return mid;
      }

      if(_chain[mid].weight < httpModules.weight) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    return -1;
  }

  @override
  String toString() {
    String string = '';
    for(int i = 0 ; i < _chain.length ; i++) {
      string += '${_chain[i].name} --> ${_chain[i].weight}\n';
    }
    return string;
  }
}


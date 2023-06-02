import '../command/alkaid_redis_command_list.dart';
class AlkaidRedisList<E> {
  final String _name;
  final AlkaidRedisCommandList _alkaidRedisCommandList;
  String get name => _name;
  AlkaidRedisCommandList get alkaidRedisCommandList  => _alkaidRedisCommandList;

  AlkaidRedisList(this._name,this._alkaidRedisCommandList);

  Future<int> length() async {
    return await _alkaidRedisCommandList.command.send_object(['llen',_name]);
  }

  void add(E value) {
    _alkaidRedisCommandList.rPush(_name, [value]);
  }

  void addAll(Iterable<E> iterable) {
    _alkaidRedisCommandList.rPush(_name, iterable.toList(growable: false));
  }

  void remove(E value) {
    _alkaidRedisCommandList.command.send_object(['lrem',_name,1,value]);
  }

  void clear() {
    _alkaidRedisCommandList.lTrim(_name, 0, -1);
  }
  
  Future<List> toList() async {
    return await _alkaidRedisCommandList.lRange(_name, 0, -1);
  }
  
}

void test() {
  List list = List.empty();
  // list.where((element) => false)
  // list.firstWhere((element) => false)
  // list.elementAt(index)
  // list.contains(element)
  // list.removeAt(index)
  // list.indexOf(element)
  // list.every((element) => false)
  // list.any((element) => false)
  // list.insert(index, element)
  // list.insertAll(index, iterable)
}
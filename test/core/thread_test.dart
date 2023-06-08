import 'dart:async';

import 'package:test/expect.dart';

void main() async {
  A a = A();

   a.set().then((value) {
     print("Hello world");
   });
   a.set();
   a.set();

  Timer(Duration(seconds: 1),() {
    print(a.list);
  });
}

class A{
  List<int>? list = [];
  int i = 0;

  int get() {
    return i;
  }

  Future<void> set() async {
    int length = list == null ? 0 : list!.length;
    if(length == 0) {
      int a = await test();
      print(a);
      await _set(a);
    }
  }

  Future<void> _set(int a) async {
    list!.add(a);
  }

  Future<int> test() async {
    return ++i;
  }
}
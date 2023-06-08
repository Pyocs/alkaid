import 'dart:mirrors';

void main() {
  print(reflectClass(A).declarations);
  print(reflectClass(B).declarations);
  print(isImpl(reflectClass(C),reflectClass(B)));
}

//判断是否为实现类
//b 是否为 a的实现类
bool isImpl(ClassMirror a,ClassMirror b) {
  bool result = true;
  a.declarations.forEach((symbol, declaration) { 
    if(declaration is MethodMirror && check(declaration)) {
      if(!b.declarations.keys.contains(symbol)) {
        result = false;
      }
    }
  });
  return result;
}

bool check(MethodMirror methodMirror) {
  return methodMirror.isAbstract && !methodMirror.isGetter && !methodMirror.isSetter
      &&  !methodMirror.isConstructor && methodMirror.simpleName != Symbol('noSuchMethod');
}

abstract class A {
  void test();
}

class B implements A {
  
  @override
  dynamic noSuchMethod(Invocation invocation) {}
  
}

class C {

}
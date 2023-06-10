import 'dart:async';
import 'package:alkaid/src/orm/alkaid_orm_manager.dart';
import 'package:alkaid/alkaid.dart';
import '../orm/class_mapping.dart';

class ClassService extends AlkaidExposeService {
  late final AlkaidOrmManager alkaidOrmManager;
  ClassService(super.name, super.expose);

  @override
  FutureOr add(param) async {
   ClassMapping classMapping = await  alkaidOrmManager.getInstance(ClassMapping);
   classMapping.insertClass(param);
   alkaidOrmManager.dispose(classMapping);
   AlkaidServer.getServer().alkaidServiceManager.mount(this);
  }

  @override
  FutureOr close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  FutureOr modify(param) async {
    ClassMapping classMapping = await alkaidOrmManager.getInstance(ClassMapping);
    classMapping.updateClassName(param);
    classMapping.startTransaction();
    classMapping.commit();
  }

  @override
  FutureOr read(param) {
    // TODO: implement read
    throw UnimplementedError();
  }

  void init() {

  }

  @override
  FutureOr remove(param) {
    // TODO: implement remove
    throw UnimplementedError();
  }


}
import 'dart:async';
import 'alkaid_service.dart';


class AlkaidListService extends AlkaidExposeService {
  final List _list = List.empty(growable: true);

  AlkaidListService(super.name, super.expose);

  List get list => _list;


  /// POST /serviceName
  /// {
  ///   "id":1,
  ///   ...
  /// }
  @override
  FutureOr add(param) {
    _list.add(param);
    return {
      "status":"ok"
    };
  }

  @override
  FutureOr close() {
    _list.clear();
  }


  @override
  FutureOr modify(param) {

  }

  @override
  FutureOr read(param) {
    return _list.where((element) => element == param);
  }

  ///DELETE /serviceName
  @override
  FutureOr remove(param) {
    return _list.remove(param);
  }



}
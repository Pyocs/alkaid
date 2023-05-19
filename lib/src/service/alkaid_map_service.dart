import 'dart:async';
import 'dart:collection';
import 'alkaid_service.dart';


///内存中的Map服务
///可以挂载到控制器中暴露API,如：
///GET /student     DELETE /student    POST /student  PUT /student

class AlkaidMapService extends AlkaidExposeService {

  ///保存资源，资源需要有名称和值
  final HashMap<dynamic,dynamic> _map = HashMap();

  AlkaidMapService(super.name, super.expose);


  ///POST /service
  ///{
  /// "id":1,
  /// "name":"admin"
  /// ...
  ///}
  @override
  FutureOr add(param) {
    _map.addEntries((param as Map).entries);
    return {
      "status":"ok"
    };
  }

  @override
  FutureOr close() {
    _map.clear();
  }


  @override
  Future modify(param) {
    // TODO: implement modify
    throw UnimplementedError();
  }

  @override
  FutureOr read(param) {
    throw UnimplementedError();
  }

  @override
  FutureOr remove(param) {
    return _map.remove(param);
  }



}
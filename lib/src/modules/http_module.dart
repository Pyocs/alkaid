import 'dart:io';
import '../exception/alkaid_server_exception.dart';
import '../core/modules_collection.dart';

abstract class HttpModules{
  late final int weight;

  late final String name;

  late final ModulesCollection modulesCollection;

  bool write = false ;

  HttpModules(this.name,{int? weight}) {
    if(weight == null) {
      this.weight = 5;
    } else if(weight <= 0 || weight >= 11) {
      throw AlkaidServerException.modulesWeightError();
    } else {
      this.weight = weight;
    }
  }

  Future check(HttpRequest request,HttpResponse response);

  Future handler(HttpRequest request,HttpResponse response);

  Future finish(HttpRequest request,HttpResponse response);

  Future later(HttpRequest request,HttpResponse response);
}
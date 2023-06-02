import 'dart:io';
import 'package:alkaid/alkaid.dart';
import '../core/modules_collection.dart';

abstract class HttpModules{
  late final int weight;

  late final String name;

  late final ModulesCollection modulesCollection;

  bool write = false ;

  HttpModules(this.name,{int? weight}) {
    if(weight == null) {
      this.weight = 5;
    } else {
      this.weight = weight;
    }
    modulesCollection = AlkaidServer.getServer().modulesCollection;
  }

  dynamic check(HttpRequest request,HttpResponse response);

  dynamic handler(HttpRequest request,HttpResponse response);

  dynamic finish(HttpRequest request,HttpResponse response);

  Future later(HttpRequest request,HttpResponse response);
}
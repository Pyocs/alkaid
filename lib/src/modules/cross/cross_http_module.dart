import 'dart:io';
import 'package:alkaid/alkaid.dart';

class CrossHttpModule extends HttpModules {
  //白名单
   final Map<String,int> _whiteList = {};
  //黑名单，如果黑名单非空，则使用黑名单的策略
  //如果黑名单、白名单都空，则默认允许所有跨域请求
  final Map<String,int> _blackList = {};

  final List<List<String>> _methodList = [[]];
  final List<List<String>> _originList = [[]];

  int _i = 0;

  int maxAge;
  CrossHttpModule(super.name,{this.maxAge = 0,super.weight});

  @override
  dynamic check(HttpRequest request, HttpResponse response) {
    if(request.method == 'OPTIONS') {
      return true;
    }
    return false;
  }

  @override
  finish(HttpRequest request, HttpResponse response) {
    // TODO: implement finish
    throw UnimplementedError();
  }

  @override
  handler(HttpRequest request, HttpResponse response) async {
    if(!check(request, response)) {
      return Future.value(AlkaidStatus.fail);
    }

    //黑名单非空,对于在黑名单中的规则，拒绝跨域请求

    if(_blackList.isNotEmpty) {
      _processRule(request, response, false);
    } else if(_whiteList.isNotEmpty) {
      _processRule(request, response, true);
    } else {
      //允许所有跨域请求
      response.statusCode = 200;
      response.headers..add(
          'Access-Control-Allow-Origin', '*')..add(
          'Access-Control-Allow-Methods', 'GET POST PUT DELETE')..add(
          'Access-Control-Allow-Headers', 'Content-type,Authorization');
      if (maxAge > 0) {
        request.headers.add('Access-Control-Max-Age', maxAge);
      }
      response.close();
    }
    return Future.value(AlkaidStatus.finish);
  }

  
  void _processRule(HttpRequest request,HttpResponse response,bool white) {
    String uri = request.uri.path;
    String? origin = request.headers.value('Access-Control-Request-Headers');
    String? method = request.headers.value('Access-Control-Request-Method');
    method ??= request.method;
    origin ??= request.requestedUri.origin;

    if(white) {
      if (_whiteList.containsKey(uri)) {
        int i = _whiteList[uri]!;
        response.statusCode = 200;
        response.headers..add(
            'Access-Control-Allow-Origin', _originList[i].join(','))..add(
            'Access-Control-Allow-Methods', _methodList[i].join(','))..add(
            'Access-Control-Allow-Headers', 'Content-type,Authorization');
        if (maxAge > 0) {
          request.headers.add('Access-Control-Max-Age', maxAge);
        }
        response.close();
      } else {
        response.statusCode = 200;
        response.close();
      }
    } else {
      if (_blackList.containsKey(uri)) {
        int i = _blackList[uri]!;
        bool a = false,
            b = false;
        if (_methodList[i].contains(method)) {
          a = true;
        } else if (_methodList[i].first == '*') {
          a = true;
        }

        if (_originList[i].contains(origin)) {
          b = true;
        } else if (_originList[i].first == '*') {
          b = true;
        }

        if (a && b) {
          response.statusCode = 200;
          response.close();
        } else {
          response.statusCode = 200;
          response.headers..add(
              'Access-Control-Allow-Origin', '*')..add(
              'Access-Control-Allow-Methods', 'GET POST PUT DELETE')..add(
              'Access-Control-Allow-Headers', 'Content-type,Authorization');
          if (maxAge > 0) {
            request.headers.add('Access-Control-Max-Age', maxAge);
          }
          response.close();
        }
      } else {
        response.statusCode = 200;
        response.headers..add(
            'Access-Control-Allow-Origin', '*')..add(
            'Access-Control-Allow-Methods', 'GET POST PUT DELETE')..add(
            'Access-Control-Allow-Headers', 'Content-type,Authorization');
        if (maxAge > 0) {
          request.headers.add('Access-Control-Max-Age', maxAge);
        }
        response.close();
      }
    }

  }

  @override
  Future later(HttpRequest request, HttpResponse response) {
    // TODO: implement later
    throw UnimplementedError();
  }

  ///向白名单中添加规则
   ///[uri] 允许跨域请求的路径
   ///[methods] 允许访问的请求方法，默认为GET POST PUT DELETE
   ///[origins] 允许访问的源站点,默认为*
  void addWhiteRule(String uri,{List<String>? methods,List<String>? origins}) {
    if(!uri.startsWith('/')) {
      uri = '/$uri';
    }
    _whiteList[uri] = _i;
    if(methods == null) {
      _methodList[_i] = ['*'];
    } else {
      _methodList[_i] = methods.map((e) => e.toUpperCase()).toList();
    }
    _originList[_i] = origins ?? ['*'];
    ++_i;
  }

  void addBlackRule(String uri,{List<String>? methods,List<String>? origins}) {
    if(!uri.startsWith('/')) {
      uri = '/$uri';
    }
    _blackList[uri] = _i;
    if(methods == null) {
      _methodList[_i] = ['*'];
    } else {
      _methodList[_i] = methods.map((e) => e.toUpperCase()).toList();
    }
    _originList[_i] = origins ?? ['*'];
    ++_i;
  }

  void cleanWhite() {
    _whiteList.clear();
  }

  void cleanBlack() {
    _blackList.clear();
  }

  void deleteWhite(String uri) {
    if(!uri.startsWith('/')) {
      uri = '/$uri';
    }

    int? i = _whiteList[uri];
    if(i == null) {
      return ;
    }
    _whiteList.remove(uri);
    _methodList.removeAt(i);
    _originList.removeAt(i);
  }

   void deleteBlack(String uri) {
     if(!uri.startsWith('/')) {
       uri = '/$uri';
     }

     int? i = _blackList[uri];
     if(i == null) {
       return ;
     }
     _blackList.remove(uri);
     _methodList.removeAt(i);
     _originList.removeAt(i);
   }

   int whiteListLength() {
    return _whiteList.keys.length;
   }

   int blackListLength() {
    return _blackList.keys.length;
   }


}
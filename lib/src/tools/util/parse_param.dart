import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';
import 'package:mime/mime.dart';

import '../../exception/alkaid_http_exception.dart';

///解析请求参数

///解析GET请求参数
Map? paramGET(HttpRequest request) {
  if(request.method != 'GET') {
    throw AlkaidHttpException.methodNotAllowed();
  }
  try {
    return request.requestedUri.queryParameters;
  } catch(e) {
    throw AlkaidHttpException.badRequest();
  }
}

///解析POST请求参数
Future<Map?> paramPOST(HttpRequest request) async {
  if(request.method != 'POST') {
    throw AlkaidHttpException.methodNotAllowed();
  }
  if(request.headers.contentType == null) {
    throw AlkaidHttpException.badRequest();
  }
  try{
    if(request.headers.contentType!.mimeType == 'application/x-www-form-urlencoded') {
      String requestBody = await utf8.decoder.bind(request).join();
      return Uri.splitQueryString(requestBody);
    } else if(request.headers.contentType!.mimeType == 'multipart/form-data') {
      Map<String,dynamic> result = {};
      //解析 multipart boundary
      String boundary = request.headers.contentType!.parameters['boundary']!;

      MimeMultipartTransformer transformer = MimeMultipartTransformer(boundary);
      Stream<MimeMultipart> parts = transformer.bind(request);

      //处理请求参数
      await for(MimeMultipart part in parts) {
        Map<String,String> disposition;
        if(part.headers['Content-Disposition'] != null) {
          disposition = _parseContentDisposition(part.headers['Content-Disposition']);
        } else if(part.headers['Content-Disposition'.toLowerCase()] != null) {
          disposition = _parseContentDisposition(part.headers['Content-Disposition'.toLowerCase()]);
        } else {
          throw AlkaidHttpException.badRequest();
        }
        String name = disposition['name']!;
        dynamic value;
        if(!part.headers.toString().toLowerCase().contains('content-type')) {
          value = String.fromCharCodes(await part.first);
        } else {
          value = await part.first;
        }
        result[name] = value;
      }
      return result;
    }
  } catch(e) {
    throw AlkaidHttpException.badRequest();
  }

  return null;
}

///解析json格式
Future<dynamic> paramJson(HttpRequest request) async {
  try {
    return json.decode(String.fromCharCodes(await request.first));
  } catch(_) {
    throw AlkaidHttpException.badRequest();
  }
}

///解析请求uri中的正则表达式
Map? paramRegex(HttpRequest request) {
  // String path = request.uri.path;
  return null;
}


Map<String,String> _parseContentDisposition(String? headerValue) {
  if(headerValue == null) {
    return {};
  }
  final Map<String,String> result = {};

  headerValue.split(';').map((String part) => part.trim()).forEach((element) {
    final int index = element.indexOf('=');
    if(index == -1) {
      return ;
    }

    final String key = element.substring(0,index).trim().toLowerCase();
    final String value = element.substring(index+1).trim();
    final String unquotedValue = value.startsWith('"') && value.endsWith('"')
        ? value.substring(1,value.length-1).trim()
        : value;

    result[key] = unquotedValue;
  });

  return result;
}

///解析参数，并反序列化到对象
///如果object[null] 为null,则返回map对象，如果不为空，则返回反序列化后的对象
dynamic parse(HttpRequest request,{dynamic object}) async {
  //如果object为空，则将参数保存到map中
  if(object == null) {
    if(request.method == 'GET') {
      return paramGET(request);
    } else if(request.method == 'POST' && request.headers.contentType != ContentType.json) {
      return paramPOST(request);
    } else if(request.headers.contentType == ContentType.json) {
      return paramJson(request);
    } else {
      throw AlkaidHttpException.badRequest();
    }
  } else {
    // if(object.runtimeType is Object().runtimeType) {
    //   throw ArgumentError('object in not  class');
    // }
    if(request.method == 'GET') {
      var param = paramGET(request);
      return _inject(param, object);
    } else if(request.method == 'POST' && request.headers.contentType!.subType != 'json') {
      var param = await paramPOST(request);
      return _inject(param, object);
    } else if(request.headers.contentType!.subType == 'json') {
      var param = await paramJson(request);
      return _inject(param, object);
    } else {
      throw AlkaidHttpException.badRequest();
    }
  }
}

///注入对象
dynamic _inject(dynamic param,dynamic object) {
  if(param == null) {
    return object;
  }
  try {
    InstanceMirror instanceMirror = reflect(object);
    ClassMirror classMirror = instanceMirror.type;
    for (var symbol in classMirror.declarations.keys) {
      var declaration = classMirror.declarations[symbol];
      if (declaration is VariableMirror) {
        String fieldName = MirrorSystem.getName(symbol);
        instanceMirror.setField(symbol, param[fieldName]);
      }
    }
  } catch(_) {
    throw AlkaidHttpException.badRequest();
  }
  return object;
}


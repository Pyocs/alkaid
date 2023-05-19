/*
  JSON Web Token由三部分组成，它们之间用圆点(.)连接。这三部分分别是：Header,Payload,Signature
Header header典型的由两部分组成：token的类型（“JWT”）和算法名称（比如：HMAC SHA256或者RSA等等）。
{
    'alg': "HS256",
    'typ': "JWT"
}
Payload JWT的第二部分是payload，它包含声明（要求）。声明是关于实体(通常是用户)和其他数据的声明。声明有三种类型: registered, public 和 private。
Registered claims : 这里有一组预定义的声明，它们不是强制的，但是推荐。比如：iss (issuer), exp (expiration time), sub (subject), aud (audience)等。
Public claims : 可以随意定义。
Private claims : 用于在同意使用它们的各方之间共享信息，并且不是注册的或公开的声明。 下面是一个例子
{
    "sub": '1234567890',
    "name": 'john',
    "admin":true
}

标准中注册的声明 (建议但不强制使用) ：
iss: jwt签发者
sub: jwt所面向的用户
aud: 接收jwt的一方
exp: jwt的过期时间，这个过期时间必须要大于签发时间
nbf: 定义在什么时间之前，该jwt都是不可用的.
iat: jwt的签发时间
jti: jwt的唯一身份标识，主要用来作为一次性token,从而回避重放攻击。
公共的声明可以添加任何的信息，一般添加用户的相关信息或其他业务需要的必要信息.但不建议添加敏感信息，因为该部分在客户端可解密.
私有声明是提供者和消费者所共同定义的声明，一般不建议存放敏感信息，因为base64是对称解密的，意味着该部分信息可以归类为明文信息。


注意，不要在JWT的payload或header中放置敏感信息，除非它们是加密的。
Signature:为了得到签名部分，你必须有编码过的header、编码过的payload、一个秘钥，签名算法是header中指定的那个，然对它们签名即可。
 */
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../../alkaid.dart';


String decodeBase64(String str) {
  var output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch(output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw AlkaidServerException('Illegal base64url string!');
  }

  return utf8.decode(base64Url.decode(output));
}

class AuthJWTToken {
  //jwt头部信息
  final SplayTreeMap<String,String> _header =
  SplayTreeMap.from({'alg':'HS256','typ':'JWT'});

  //客户端地址
  String? ipAddress;
  //生命周期
  num lifeSpan;
  //用户id(唯一)
  String userId;
  //发行时间
  late DateTime issuedAt;
  //有效负载
  Map<String,dynamic> payload = {};

  AuthJWTToken({
    this.ipAddress,
    this.lifeSpan = -1,
    required this.userId,
    DateTime? issuedAt,
    Map<String,dynamic>? payload
  }) {
    this.issuedAt = issuedAt ?? DateTime.now();
    if(payload != null) {
      this.payload.addAll(payload.keys.fold({}, (out, k) => out?..[k.toString()] = payload[k]) ?? {});
    }
  }

  factory AuthJWTToken.fromJson(String msg) => AuthJWTToken.fromMap(json.decode(msg) as Map<String,dynamic>);

  factory AuthJWTToken.fromMap(Map<String,dynamic> data) {
    return AuthJWTToken(
        ipAddress: data['aud'].toString(),
        lifeSpan: data['exp'] as num,
        issuedAt: DateTime.parse(data['iat'].toString()),
        userId: data['sub'],
        payload: data['pld']
    );
  }

  factory AuthJWTToken.parse(String jwt) {
    var split = jwt.split('.');

    if(split.length != 3) {
      throw AlkaidServerException('解析jwt失败:$jwt');
    }

    var payloadString = decodeBase64(split[1]);
    return AuthJWTToken.fromMap(json.decode(payloadString) as Map<String,dynamic>);
  }

  factory AuthJWTToken.validate(String jwt,Hmac hmac) {
    var split = jwt.split('.');

    if(split.length != 3) {
      throw AlkaidServerException('jwt Invalid error $jwt');
    }

    //负载部分
    // var payloadString = split[1];
    var payloadString = decodeBase64(split[1]);
    var data = '${split[0]}.${split[1]}';
    //签名
    var signature = base64Url.encode(hmac.convert(data.codeUnits).bytes);

    if (signature != split[2]) {
      throw AlkaidHttpException.unauthorized(message: 'JWT payload does not match hashed version');
    }
    return AuthJWTToken.fromMap(json.decode(payloadString) as Map<String,dynamic>);
  }

  String serialize(Hmac hmac) {
    var headerString = base64Url.encode(json.encode(_header).codeUnits);
    var payloadString = base64Url.encode(json.encode(toJson()).codeUnits);
    var data = '$headerString.$payloadString';
    var signature = hmac.convert(data.codeUnits).bytes;
    return '$data.${base64Url.encode(signature)}';
  }

  Map<String, dynamic> toJson() {
    return _splayIfy({
      'iss': 'alkaid',
      'aud': ipAddress,
      'exp': lifeSpan,
      'iat': issuedAt.toIso8601String(),
      'sub': userId,
      'pld': _splayIfy(payload)
    });
  }

  Map<String,dynamic> _splayIfy(Map<String,dynamic> map) {
    return SplayTreeMap.from(map);
  }

  dynamic _splay(dynamic value) {
    if(value is Iterable) {
      return value.map(_splay).toList();
    } else if(value is Map) {
      return _splayIfy(value as Map<String,dynamic>);
    } else {
      return value;
    }
  }

}
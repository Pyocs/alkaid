import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../../../alkaid.dart';
import '../auth_options.dart';
import '../auth_strategy.dart';
import 'auth_jwt_token.dart';

///JWT用户认证服务
class AlkaidJWTAuthService<User> extends AlkaidInternalService {

  final Random _random = Random();
  final RegExp _rgxBearer = RegExp(r'^Bearer');

  //hmac的密钥应该定期更换
  late final Hmac _hs256;
  //允许在cookie 中添加token:Bearer xxx
  //允许jwt储存在token中
  final bool allowCookie;
  //允许在请求uri中添加token
  final bool allowTokenInQuery;
  final bool secureCookies;
  final String? cookieDomain;
  final String cookiePath;
  final bool enforceIp;
  final bool addCookieExpires;
  //jwtLifeSpan 应该确保 <= sessionTimeout
  late final int _jwtLifeSpan;
  //存储认证策略
  Map<String,AuthStrategy<User>> strategies = {};
  FutureOr<String> Function(User) serializer;
  FutureOr<User> Function(String) deserializer;
  Hmac get hamc => _hs256;

  AlkaidJWTAuthService(super.name,{
    String? jwtKey,
    required this.serializer,
    required this.deserializer,
    this.allowCookie = true,
    this.allowTokenInQuery = true,
    this.enforceIp = true,
    this.cookieDomain,
    this.cookiePath = '/',
    this.secureCookies = true,
    this.addCookieExpires = true,
    int? jwtLifeSpan
  }) {
    _hs256 = Hmac(sha256, (jwtKey ?? _randomString(32)).codeUnits);
    if(jwtLifeSpan != null) {
      _jwtLifeSpan = jwtLifeSpan;
    } else {
      //默认与sessionTimeout生命周期相同
      _jwtLifeSpan = AlkaidServer.getServer().sessionTimeout;
    }
  }



  //获取请求中的jwt token,如果反序列化成功，则返回user,token
  //如果没有token,则抛出401
  @override
  Future<Map<String,dynamic>> accept(HttpRequest request, HttpResponse response) {
    try {
      return Future.value(_reviveJwt(request, response));
    } catch(e) {
      rethrow;
    }
  }

  @override
  FutureOr close() {
    strategies.clear();
  }


  //尝试恢复仍然生效的JWT。
  //user token
  Map<String,dynamic> _reviveJwt(HttpRequest request,HttpResponse response) {
    var jwt = _getJwt(request);
    if(jwt == null) {
      throw AlkaidHttpException.forbidden(message: 'No JWT provided');
    }
    try {
      var token = AuthJWTToken.validate(jwt, _hs256);
      if(enforceIp && request.connectionInfo?.remoteAddress.address != token.ipAddress) {
        throw AlkaidHttpException.forbidden(message: 'JWT cannot be accessed from this IP address.');
      }

      if(token.lifeSpan > -1) {
        //如果到期，则抛出异常，重新登陆获取jwt
        var expiry = token.issuedAt
            .add(Duration(seconds: token.lifeSpan.toInt()));
        if(!expiry.isAfter(DateTime.now())) {
          throw AlkaidHttpException.unauthorized(message:  'Token has expired. Please re-authenticate');
        }
      }

      if(allowCookie) {
        _addProtectedCookie(response, 'token', token.serialize(_hs256));
      }
      return {
        'user':deserializer(token.userId),
        'token':token.serialize(_hs256)
      };
    } catch(e) {
      if(e is AlkaidHttpException) {
        rethrow;
      }
      throw AlkaidHttpException.badRequest(message: 'Malformed JWT');
    }
  }

  //使用一种或多种策略对用户进行认证
  //如果认证成功，则生成jwt,添加到cookie中
  //如果认证失败，则返回401
  dynamic authenticate(List<String> names,[AuthOptions<User>? options]) {
    return (HttpRequest request,HttpResponse response) async {
      for(int i = 0 ; i < names.length ; i++) {
        var strategy = strategies[names[i]];
        if(strategy == null) {
          throw AlkaidServerException('No strategy ${names[i]} found');
        }
        var user = await strategy.authenticate(request, response);
        if(user != null) {
          var userId = await serializer(user);
          AuthJWTToken authToken = AuthJWTToken(userId: userId,
              lifeSpan: _jwtLifeSpan,ipAddress: request.connectionInfo?.remoteAddress.address,
              issuedAt: DateTime.now());
          if(options != null && options.authTokenCallback != null) {
            var r = await options.authTokenCallback!.call(request,response,authToken,user);
            if(r != null) {
              return r;
            }
          }
          String jwt = authToken.serialize(_hs256);
          if(allowCookie) {
            _addProtectedCookie(response, 'token',jwt);
          }
          if(options != null && options.authCallback != null) {
            var r = await options.authCallback!.call(request,response,jwt);
            if(r != null) {
              return r;
            }
          }

          if(options != null && options.successRedirect != null) {
            response.redirect(Uri.parse(options.successRedirect!));
          } else {
            response.headers.contentType = ContentType.json;
            response.write('ok');
            response.close();
          }
        } else {
          if(i < names.length - 1) continue;
          //如果没有重定向
          if(response.statusCode == 301 || response.statusCode == 302) {
            return ;
          }
          if(options != null && options.failRedirect != null) {
            response.redirect(Uri.parse(options.failRedirect!));
          } else {
            throw AlkaidHttpException.unauthorized();
          }
        }
      }
    };
  }


  //从请求中提取jwt
  //Authorization token query 中必须包含Bearer
  String? _getJwt(HttpRequest request) {
    if(request.headers.value('Authorization') != null) {
      String authHeader = request.headers.value('Authorization')!;
      if(_rgxBearer.hasMatch(authHeader)) {
        return authHeader.replaceAll(_rgxBearer, '').trim();
      }
    } else if(allowCookie && request.cookies.any((element) => element.name == 'token')) {
      String token = request.cookies.firstWhere((element) => element.name == 'token').value;
      return token;
    } else if(allowTokenInQuery) {
      String? token = request.uri.queryParameters['token'];
      if(token != null) {
        return token;
      }
    }
    return null;
  }

  void _addProtectedCookie(HttpResponse response,String name,String value) {
    //cookie中的jwt是否需要添加过期时间?
    Cookie cookie = Cookie(name, value);
    cookie
      ..path = cookiePath
      ..domain = cookieDomain;

    if(secureCookies) {
      cookie.httpOnly = true;
      if(AlkaidServer.getServer().hasSecure) {
        cookie.secure = true;
      }
    }

    if(addCookieExpires) {
      cookie.expires = DateTime.now().add(Duration(seconds: _jwtLifeSpan));
      cookie.maxAge = _jwtLifeSpan;
    }
    response.cookies.add(cookie);
  }

  String _randomString(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
        Iterable.generate(n,(_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }

}
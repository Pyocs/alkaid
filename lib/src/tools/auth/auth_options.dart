import 'dart:async';
import 'dart:io';

import 'jwt/auth_jwt_token.dart';

///生成token回调函数
typedef AuthCallback = FutureOr Function(HttpRequest request,HttpResponse response,String token);

///生成AuthToken回调函数
///默认返回null
typedef AuthTokenCallback<User> = FutureOr Function(HttpRequest request,HttpResponse response,AuthJWTToken authToken,User user);

class AuthOptions<User> {
  AuthCallback? authCallback;
  AuthTokenCallback<User>? authTokenCallback;

  ///验证成功重定向url
  String? successRedirect;
  ///验证失败重定向url
  String? failRedirect;

  ///验证默认成功返回true
  bool canRespondWithJson;

  AuthOptions({
    this.authCallback,
    this.authTokenCallback,
    this.canRespondWithJson = true,
    this.successRedirect,
    this.failRedirect
  });

}
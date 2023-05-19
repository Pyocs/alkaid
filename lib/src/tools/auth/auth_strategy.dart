//身份验证策略
import 'dart:async';
import 'dart:io';

import 'auth_options.dart';


///身份验证策略
abstract  class AuthStrategy<User> {
  FutureOr<User?> authenticate(HttpRequest request,HttpResponse response,
      [AuthOptions<User>? options]);
}
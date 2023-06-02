// import 'dart:convert';
// import 'dart:io';
import 'dart:async';
// import 'package:hello/modules/exception/alkaid_http_exception.dart';
// import 'package:hello/tools/auth/auth_options.dart';
// import 'package:hello/tools/auth/auth_strategy.dart';
//
// //确定传入用户名和密码的有效性。
typedef LocalAuthVerifier<User> = FutureOr<User?> Function(String? username,String? password);
//
// ///HTTP Basic验证方案
// ///Basic验证的安全性很差
// ///由于用户 ID 与密码是是以明文的形式在网络中进行传输的（尽管采用了 base64 编码，但是 base64 算法是可逆的），所以基本验证方案并不安全
// /*
//   Client: GET / HTTP/1.1
//   Server: HTTP/1.1 401 WWW-Authenticate:Basic realm="$realm"
//   Client: GET / HTTP/1.1 Authorization:Basic yWxhXAxs.... (username:password)使用base64加密
//  */
//
// class BasicAuthStrategy<User> extends AuthStrategy<User> {
//
//   final RegExp _rgxBasic = RegExp(r'^Basic (.+)$', caseSensitive: false);
//   final RegExp _rgxUsrPass = RegExp(r'^([^:]+):(.+)$');
//
//   LocalAuthVerifier<User> verifier;
//   String usernameField;
//   String passwordField;
//   String invalidMessage;
//   final bool allowBasic;
//   final bool forceBasic;
//   String realm;
//
//   BasicAuthStrategy(this.verifier,
//   {this.usernameField = 'username',
//   this.passwordField = 'password',
//     this.invalidMessage = 'Please provide a valid username and password.',
//     this.allowBasic = true,
//     this.forceBasic = false,
//     this.realm = 'Authentication is required.'
//   })
//
//
//
//
//
//   // FutureOr<User?> authenticate(HttpRequest request,HttpResponse response,[AuthOptions<User>? options]) async {
//   //   options ??= AuthOptions<User>();
//   //   User? verificationResult;
//   //
//   //   //在HTTP Basic Authentication中，客户端会将用户名和密码用冒号（:）连接起来，
//   //   // 然后进行Base64编码，最后将编码结果放在Authorization请求头中，形式如下：
//   //   //Authorization: Basic base64(username:password)
//   //   if(allowBasic) {
//   //     var authHeader = request.headers.value('authorization') ?? '';
//   //     if(_rgxBasic.hasMatch(authHeader)) {
//   //       var base64AuthString = _rgxBasic.firstMatch(authHeader)?.group(0);
//   //       if(base64AuthString == null) {
//   //         return null;
//   //       }
//   //       var authString = String.fromCharCodes(base64.decode(base64AuthString));
//   //       if(_rgxUsrPass.hasMatch(authString)) {
//   //         Match usrPassMatch = _rgxUsrPass.firstMatch(authString)!;
//   //         verificationResult =
//   //             await verifier(usrPassMatch.group(1),usrPassMatch.group(2));
//   //       } else {
//   //         throw AlkaidHttpException.badRequest();
//   //       }
//   //
//   //       if(verificationResult == null ) {
//   //         response
//   //             ..statusCode = 401
//   //             ..headers.add('www-authenticate', 'Basic realm="$realm"');
//   //         response.close();
//   //         return null;
//   //       }
//   //       return verificationResult;
//   //     }
//   //   }
//   //
//   //   if(verificationResult == null || verificationResult is Map && verificationResult.isEmpty) {
//   //     if(options.failRedirect != null && options.failRedirect!.isNotEmpty) {
//   //       //重定向到failRedirect
//   //       response.redirect(Uri.parse(options.failRedirect!));
//   //       return null;
//   //     }
//   //
//   //     if(forceBasic) {
//   //       response.headers.add('www-authenticate', 'Basic realm="$realm"');
//   //       return null;
//   //     }
//   //     return null;
//   //   }
//   //   return null;
//   // }
//
//
//
// }
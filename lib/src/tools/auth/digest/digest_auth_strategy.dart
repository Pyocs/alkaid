import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../../../alkaid.dart';
import '../../../../tools.dart';
import '../basic/basic_auth_strategy.dart';
import 'digest_manager.dart';
import 'digest_message.dart';


///Digest 访问身份验证是一种用于Web的访问身份验证协议，
///相较于基本访问认证(Basic Authentication)，它为Web安全提供了更强的保护机制。
///在基本访问认证中，用户名和密码是以明文的形式发送的，而在摘要访问认证中，密码是被加密的。
/*
  客户端发送一个请求到服务器。
  Client: GET /resource HTTP/1.1
  Host: www.example.com

  如果服务器需要身份验证，那么它将返回一个401未授权的响应，并在响应头中包含一个"WWW-Authenticate"的字段。这个字段的值包含了一些信息，比如认证的域、一个唯一的随机数(nonce)等。
  Server: HTTP/1.1 401 Unauthorized
  WWW-Authenticate: Digest realm="testrealm@host.com",
                        qop="auth,auth-int",
                        nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
                        opaque="5ccc069c403ebaf9f0171e9517f40e41"

  客户端在接收到401未授权的响应后，将使用用户名和密码（以及其他从"WWW-Authenticate"字段中得到的信息）生成一个摘要响应(digest response)。然后，客户端将再次发送请求，但这次在请求头中包含了一个"Authorization"字段，这个字段的值就是生成的摘要响应。
  Client: GET /resource HTTP/1.1
  Host: www.example.com
  Authorization: Digest username="Mufasa",
                      realm="testrealm@host.com",
                      nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
                      uri="/dir/index.html",
                      qop=auth,
                      nc=00000001,
                      cnonce="0a4f113b",
                      response="6629fae49393a05397450978507c4ef1",
                      opaque="5ccc069c403ebaf9f0171e9517f40e41"

  服务器在接收到含有"Authorization"字段的请求后，将使用相同的信息（用户名、密码、nonce等）来生成自己的摘要响应。然后，服务器将比较自己生成的摘要响应和客户端发送过来的摘要响应。如果两者相同，那么服务器将允许客户端访问请求的资源。
  Server: HTTP/1.1 200 OK

 */
//根据用户名获取密码
typedef DigestAuthVerifier = FutureOr<String?> Function(String? username);
class DigestAuthStrategy<User> extends AuthStrategy<User> {

  //获取密码，生成response
  final DigestAuthVerifier verifier;
  //根据用户名密码生成user
  final LocalAuthVerifier<User> localAuthVerifier;

  final DigestManager _digestManager = DigestManager();

  DigestAuthStrategy(this.verifier, this.localAuthVerifier);


  /*
    判断请求标头是否有Authorization
      如果有：获取sessionID,比对nonce qop realm是否相同、请求次数是否正常，没有异常比对响应是否正确，返回结果
      如果没有返回401,进行认证
      如果比对结果不对，再次生成随机数进行认证
   */
  @override
  FutureOr<User?> authenticate(HttpRequest request, HttpResponse response, [AuthOptions<User>? options]) async {
    options ??= AuthOptions();

    var authHeader = request.headers['Authorization'];
    if(authHeader == null) {
      DigestMessage? digestMessage = _digestManager.get(request.session.id);
      if(digestMessage == null) {
        digestMessage =  DigestMessage.fromServer(realm: request.requestedUri.authority, nonce: _randomString(32),qop: 'auth,auth-int',opaque: 'test');
        _digestManager.add(request.session.id, digestMessage);
      }
      response
        ..statusCode = 401
        ..headers.set('WWW-Authenticate', 'Digest ${digestMessage.serverString()}');
      response.close();
      return null;
    }

    DigestMessage? old = _digestManager.get(request.session.id);
    if(old == null) {
      DigestMessage digestMessage =  DigestMessage.fromServer(realm: request.requestedUri.authority, nonce: _randomString(32),qop: 'auth,auth-int');
      _digestManager.add(request.session.id, digestMessage);
      response
        ..statusCode = 401
        ..headers.set('WWW-Authenticate', 'Digest ${digestMessage.serverString()}');
      await response.close();
      return null;
    }

    DigestMessage digestMessage = DigestMessage.parse(authHeader.join(','));
    if(( old.realm != digestMessage.realm || old.nonce != digestMessage.nonce ) || (digestMessage.qop != null && !old.qop!.contains(digestMessage.qop!) )) {
      throw AlkaidHttpException.badRequest();
    }

    String? password = await verifier.call(digestMessage.username);
    if(password == null) {
      //验证失败
      _digestManager.remove(request.session.id);
      // throw AlkaidHttpException.unauthorized('not user');
      return null;
    }
    if(digestMessage.response! == generateResponse(digestMessage, password, request.method)) {
      //验证成功
      _digestManager.remove(request.session.id);
      // response.close();
      return await localAuthVerifier.call(digestMessage.username,password);
    } else {
      //验证失败
      _digestManager.remove(request.session.id);
      return null;
      // throw AlkaidHttpException.unauthorized('error!');
    }
  }


  String generateResponse(DigestMessage message,String password,String method) {
    var ha1 = md5.convert(utf8.encode('${message.username}:${message.realm}:$password'));
    var ha2 = md5.convert(utf8.encode('$method:${message.uri}'));
    String temp = '';
    //nc cnonce qop 这三个必须同时提供
    if(message.nc == null && message.cnonce == null && message.qop == null) {
      temp = message.nonce;
    } else if(message.nc != null && message.cnonce != null && message.qop != null){
      temp = '${message.nonce}:${message.nc}:${message.cnonce}:${message.qop}';
    } else {
      throw AlkaidHttpException.badRequest();
    }
    var response = md5.convert(utf8.encode('$ha1:$temp:$ha2'));
    return response.toString();
  }


  String _randomString(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
        Iterable.generate(n,(_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

}



import 'dart:io';
import 'dart:async';

import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/tools/auth.dart';
import 'package:alkaid/src/tools/auth/oauth2/external_auth_options.dart';

///与第三发认证服务器交互
/*
  OAuth 2.0认证流程包括以下步骤：

注册应用程序（客户端）：

应用程序需要在认证服务器上注册，并获取唯一的客户端ID和客户端密钥。
重定向用户到认证服务器：

应用程序将用户重定向到认证服务器，以获取用户的授权。
包括以下参数：
response_type：指定授权服务器返回的响应类型，通常为code表示授权码流程，或者token表示隐式授权流程。
client_id：应用程序的客户端ID。
redirect_uri：用于接收认证服务器返回授权码或访问令牌的重定向URI。
scope：请求的权限范围，用于指定应用程序请求访问的资源。
state：可选参数，用于防止跨站请求伪造（CSRF）攻击。
用户授权：

用户在认证服务器上登录并授权应用程序访问其受保护的资源。
用户可以选择接受或拒绝授权请求。
认证服务器重定向回应用程序：

认证服务器将用户重定向回应用程序，并附带授权码或访问令牌（取决于使用的授权流程）。
获取访问令牌：

应用程序使用授权码（如果使用授权码流程）或直接从认证服务器获得的访问令牌（如果使用隐式授权流程），向认证服务器请求访问令牌。
包括以下参数：
grant_type：指定使用的授权类型，通常为authorization_code表示授权码流程，或者implicit表示隐式授权流程。
client_id：应用程序的客户端ID。
client_secret：应用程序的客户端密钥（仅在授权码流程中需要）。
code：授权码（仅在授权码流程中使用）。
redirect_uri：用于接收认证服务器返回访问令牌的重定向URI（仅在授权码流程中使用）。
验证和颁发访问令牌：

认证服务器验证请求中的参数和身份，并根据验证结果颁发访问令牌和刷新令牌。
访问受保护的资源：

应用程序使用访问令牌来请求受保护的资源，向资源服务器提供访问令牌。
资源服务器验证访问令牌的有效性，并根据访问令牌授权或拒绝对资源的访问。

  刷新访问令牌（可选）：

如果访问令牌过期，应用程序可以使用刷新令牌向认证服务器请求新的访问令牌，而无需用户重新进行授权。
应用程序向认证服务器发送刷新令牌请求，包括以下参数：
grant_type：指定为refresh_token，表示刷新令牌流程。
client_id：应用程序的客户端ID。
client_secret：应用程序的客户端密钥（仅在某些情况下需要）。
refresh_token：用于刷新访问令牌的刷新令牌。
重复访问受保护的资源：

应用程序可以使用新获得的访问令牌来重复访问受保护的资源。
资源服务器验证访问令牌的有效性，并根据访问令牌授权或拒绝对资源的访问。
需要注意的是，OAuth 2.0支持不同的授权流程，包括授权码流程（Authorization Code Flow）、隐式授权流程（Implicit Flow）、密码凭证流程（Resource Owner Password Credentials Flow）和客户端凭证流程（Client Credentials Flow）。每个流程的细节和步骤略有不同，但整体的认证流程框架是相似的。

另外，实际的OAuth 2.0实现可能会根据不同的认证服务器和应用程序需求进行适当的定制和扩展。因此，在实际应用中，建议参考相应的OAuth 2.0认证服务器的文档和规范以及应用程序的要求来执行认证流程。
 */
class OAuth2Strategy<User> implements AuthStrategy<User> {


  @override
  FutureOr<User?> authenticate(HttpRequest request, HttpResponse response, [AuthOptions<User>? options]) {


    // TODO: implement authenticate
    throw UnimplementedError();
  }


}
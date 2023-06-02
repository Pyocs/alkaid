import 'package:alkaid/alkaid.dart';

///外部认证选项(OAuth2)

class ExternalAuthOptions {
  //应用程序id
  final String clientId;

  //应用程序密钥
  final String clientSecret;

  //重定向uri
  final Uri redirectUri;

  //传递给授权服务器的范围
  final Set<String> scopes;

  ExternalAuthOptions._(
      this.clientId,this.clientSecret,
      this.redirectUri,this.scopes
      );

  factory ExternalAuthOptions({
      required String clientId,
      required String clientSecret,
      required redirectUri,
      Iterable<String> scopes = const []
    }) {
    if(redirectUri is String) {
      return ExternalAuthOptions._(clientId, clientSecret, Uri.parse(redirectUri), scopes.toSet());
    } else if(redirectUri is Uri) {
      return ExternalAuthOptions._(clientId, clientSecret, redirectUri, scopes.toSet());
    } else {
      throw AlkaidServerException('can not parse $redirectUri');
    }
  }

  factory ExternalAuthOptions.fromMap(Map<String,dynamic> map) {
    var clientId = map['client_id'];
    var clientSecret = map['client_secret'];
    if(clientId == null || clientSecret == null) {
      throw AlkaidServerException('Invalid clientId or  clientSecret');
    }
    return ExternalAuthOptions(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: map['redirect_uri'],
      scopes: map['scopes'] is Iterable
        ? (map['scopes'] as Iterable).map((e) => e.toString())
        : <String>[]
    );
  }

  @override
  int get hashCode => Object.hashAll([clientId,clientSecret,redirectUri,scopes]);

  @override
  bool operator ==(Object other) {
    return other is ExternalAuthOptions
        && other.clientId == clientId
        && other.clientSecret == clientSecret
        && other.redirectUri == redirectUri
        //equals
        && other.scopes == scopes;
  }

  ExternalAuthOptions copyWith({
    String? clientId,
    String? clientSecret,
    redirectUri,
    Iterable<String> scopes = const []
  }) {
    return ExternalAuthOptions(
      clientId: clientId ?? this.clientId,
      clientSecret:  clientSecret ?? this.clientSecret,
      redirectUri:  redirectUri ?? this.redirectUri,
      //followedBy 返回可迭代对象与该对象的惰性串联
      scopes: scopes.followedBy(this.scopes)
    );
  }

  Map<String,dynamic> toJson() {
    return {
      "client_id":clientId,
      "client_secret":clientSecret,
      "redirect_uri":redirectUri.toString(),
      "scopes":scopes.toList()
    };
  }

  @override
  String toString({bool obscureSecret = true,int? asteriskCount}) {
    String? secret;

    if(!obscureSecret) {
      secret = clientSecret;
    } else {
      var codeUnits = List<int>.filled(asteriskCount ?? clientSecret.length, '*'.codeUnits.first);
      secret = String.fromCharCodes(codeUnits);
    }

    var output = StringBuffer('ExternalAuthOptions(');
    output
      ..write('clientId=$clientId')
      ..write(', clientSecret=$secret')
      ..write(', redirectUri=$redirectUri')
      ..write(', scopes=${scopes.toList()}')
      ..write(')');
    return output.toString();
  }

}
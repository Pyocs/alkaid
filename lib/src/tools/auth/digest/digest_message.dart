
class DigestMessage {

  String? username;

  //由服务器提供，告诉客户端认证的领域或范围
  String realm;
  //客户端请求的url
  String? uri;
  //质量保护，可选值:auth(只对认证进行保护)、auth-int(对认证和请求内容进行保护)
  String? qop;
  //十六进制计数器，表示这是客户端发送的第几个请求
  String? nc;
  //客户端生成的随机数，计算响应时会用到
  String? cnonce;
  //服务端返回的随机数
  String nonce;
  //客户端计算出来的响应,它是基于以上所有的参数以及用户的密码计算出来的。
  String? response;
  //一个字符串，由服务器提供，然后由客户端返回给服务器，可以实现一切额外的功能，如保存状态信息等
  String? opaque;
  String? algorithm;


  DigestMessage._({
    this.username,
    required this.realm,
    this.uri,
    this.qop,
    this.nc,
    this.cnonce,
    this.response,
    this.opaque,
    required this.nonce
  });

  factory DigestMessage.fromServer({required String realm,required String qop,required String nonce,String? opaque}) {
    return DigestMessage._(realm: realm, qop: qop,opaque: opaque,nonce: nonce);
  }

  factory DigestMessage.fromClient({
    required String username,
    required String realm,
    required String uri,
    String? qop,
    String? nc,
    String? cnonce,
    required String response,
    required String nonce,
    String? opaque,
    String? algorithm
  }) {
    return DigestMessage._(username: username,realm: realm,uri: uri,qop: qop,nc: nc,cnonce: cnonce,response: response,opaque: opaque,nonce: nonce);
  }

  String serverString() {
    if(opaque != null) {
      return 'realm="$realm",qop="$qop",nonce="$nonce",opaque="$opaque"';
    } else {
      return 'realm="$realm",qop="$qop",nonce="$nonce"';
    }
  }

  factory DigestMessage.parse(String header) {
    if(header.contains('Digest')) {
      header = header.replaceAll('Digest', '').trim();
    }
    var splits = header.split(',');
    late String username;
    late String realm;
    late String uri;
    String? qop;
    String? nc;
    String? cnonce;
    late String nonce;
    late String response;
    String? opaque;
    String? algorithm;

    for(var split in splits) {
      if(split.contains('username')) {
        username = split.split("=")[1].replaceAll('"', '');
      } else if(split.contains('realm')) {
        realm = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('uri')) {
        uri = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('qop')) {
        qop = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('nc') && !split.contains('nonce')) {
        nc = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('cnonce')) {
        cnonce = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('nonce')) {
        nonce = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('response')) {
        response = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('opaque')) {
        opaque = split.split('=')[1].replaceAll('"', '');
      } else if(split.contains('algorithm')) {
        algorithm = split.split('=')[1].replaceAll('"', '');
      } else {
        throw 'Can not identify $split';
      }
    }
    return DigestMessage.fromClient(
        username: username,
        realm: realm,
        uri: uri,
        qop: qop,
        nc: nc,
        cnonce: cnonce,
        nonce: nonce,
        response: response,
        opaque: opaque,
        algorithm: algorithm
    );
  }



}
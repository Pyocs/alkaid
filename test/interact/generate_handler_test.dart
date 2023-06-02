import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:alkaid/alkaid.dart';
import 'package:alkaid/interact/isolation/proxy_method.dart';

///AI生成处理请求方法测试
Random _random = Random();
late AlkaidServer alkaidServer;
void main() async {
  alkaidServer = await  AlkaidServer.server('localhost', 3000);
  await alkaidServer.start();
  // generateHandlerMethod('Write a POST processing method to determine whether the username and password are admin, 123 If correct, return json:{status:"ok"}, otherwise {status:"error"}');
  String input = '''
@POST('/login')
Future login(HttpRequest request, HttpResponse response) async {
  String rawData = await utf8.decoder.bind(request).join(); // decode body of request
  Map<String, dynamic> data = jsonDecode(rawData); // convert to map
  String username = data['username']!;
  String password = data['password']!;
  
  if (username == 'admin' && password == '123') {
    response.headers.add(HttpHeaders.contentTypeHeader, "application/json");
    String jsonBody = '{"status": "ok"}'; // successful login
    response.write(jsonBody);
  } else {
    response.headers.add(HttpHeaders.contentTypeHeader, "application/json");
    String jsonBody = '{"status": "error"}'; // failed login
    response.write(jsonBody);
  }
  
  response.close();
  
  return Future.value();
}

''';
  process(input);



}

///[input] AI生成的处理方法
void process(String input) {
  bool first = true;
  File file = File('/home/pyoc/Documents/IdeaProject/alkaid/lib/interact/isolation/test');
  //将ai生成的方法添加到测试文件中
  String content = file.readAsStringSync();

  //处理方法名称
  String methodName;
  methodName = input.substring(input.indexOf('Future'),input.indexOf('(HttpRequest')).replaceAll('Future', '').trim();
  print(methodName);
  content = content.replaceAll('#replace', '$methodName(request,request.response);');
  content += '\n$input';

  String tempName = _randomString(6);
   file = File('.$tempName.dart');
   file.writeAsString(content);

   //注解中的请求方法
  String name1 = input.substring(input.indexOf('@'),input.indexOf('(')).replaceAll('@', '').trim();
  //注解中的请求路径
  String name2 = input.substring(input.indexOf(name1),input.indexOf(')')).replaceAll(name1, '').replaceAll('(', '').trim().replaceAll("'", '').trim();

  Process.start('dart', ['.$tempName.dart']).then((process) {
    process.stdout.transform(utf8.decoder).listen((event) {
      if(first) {
        int port = int.parse(event);
        addIsolateMethod(alkaidServer, name2, name1, 'http://localhost:$port');
        first = false;
      } else {
        print(event);
      }
    });
    process.stdin.addStream(stdin);
    process.stderr.transform(utf8.decoder).listen(print);
  });

}



String _randomString(int n) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
      Iterable.generate(n,(_) => chars.codeUnitAt(_random.nextInt(chars.length)))
  );
}
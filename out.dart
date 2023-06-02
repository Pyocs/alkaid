import 'dart:convert';
import 'dart:io';
import 'package:alkaid/alkaid.dart';

void main() async {
  HttpServer httpServer = await HttpServer.bind('localhost',0);
  print(httpServer.port);
  httpServer.listen((request) {
    login(request,request.response);
  });

  stdin.transform(utf8.decoder).listen((event)  async {
    if(event == 'exit') {
      await httpServer.close();
      exit(0);
    }
  });
}




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


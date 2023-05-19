import 'package:alkaid/alkaid.dart';

void main() async {
  AlkaidServer alkaidServer = await  AlkaidServer.server('localhost', 3000);
  await alkaidServer.start();
  alkaidServer.routerHttpModule.get('/hello', (request, response)  {
    response.write('Hello world\n');
    response.close();
    return Future.value(AlkaidStatus.finish);
  });

}

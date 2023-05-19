import 'dart:async';
import 'dart:convert';
import 'dart:io';

///处理体积较大的媒体文件
///体积多大才算大呢？ 50M? 100M?

///将文件Stream 加入响应中
Future<void> readFileInChucks(HttpResponse response,File file) async {
  final fileSize = await  file.length();
  response.headers.set('Content-Length', fileSize.toString());

  // final controller = StreamController<List<int>>();
  // final stream = controller.stream;

  try {
    await response.addStream(file.openRead());
  } catch (e) {
    rethrow;
  } finally {
    response.close();
  }
}

///分块编码传输
Future<void> chuckedTransfer(HttpResponse response,File file) async {
  response.headers.set('Transfer-Encoding', 'chunked');
  try{
    final input = file.openRead();
    await for(final chuck in input) {
      response.add(_encodeChuck(chuck));
    }
    response.add(_encodeChuck([])); //add 0-size chuck to end the response
  } catch(e) {
    rethrow;
  } finally {
    response.close();
  }
}

List<int> _encodeChuck(List<int> data) {
  //转换为16进制编码
  final size = data.length.toRadixString(16);
  final header = '$size\r\n';
  final footer = '\r\n';
  return utf8.encode(header) + data + utf8.encode(footer);
}
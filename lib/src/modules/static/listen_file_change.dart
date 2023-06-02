import 'dart:async';
import 'dart:io';
import 'package:alkaid/alkaid.dart';
import 'package:io/ansi.dart';
import 'package:watcher/watcher.dart';
import 'package:crypto/crypto.dart';
///监听文件是否发生改变，重新生成ETag
class ListenFileChange {
  final StreamController<WatchEvent> _onChange = StreamController<WatchEvent>.broadcast();

  //存储文件的eTag
  //filePath => eTag
  final Map<String,String> _eTags = {};
  final List<StreamSubscription> _subscriptions = [];
  Stream<WatchEvent> get onChange => _onChange.stream;
  Map<String,String> get eTage => _eTags;

  ListenFileChange();

  void _init(String path) {
    var stat = FileStat.statSync(path);
    if(stat.type == FileSystemEntityType.file) {
      if(!File(path).existsSync()) {
        throw AlkaidServerException('$path不存在');
      }
    } else if(stat.type == FileSystemEntityType.directory) {
      if (!Directory(path).existsSync()) {
        throw AlkaidServerException('$path不存在');
      }
    }else if(stat.type == FileSystemEntityType.link) {
        path = Link(path).resolveSymbolicLinksSync();
        _init(path);
        return ;
      }


    var watcher = Watcher(path);
    var p = watcher.events.listen(_onChange.add,onError: (e) {
      print(red.wrap(e));
    });
    _subscriptions.add(p);

    //是否需要将文件夹内的所有文件初始化？
    if(stat.type == FileSystemEntityType.file) {
      _eTags[path] = eTag(path)!;
    } else if(stat.type == FileSystemEntityType.directory) {
      Directory directory = Directory(path);
      var lists = directory.listSync(recursive: true);
      for(var list in lists) {
        if(list.statSync().type == FileSystemEntityType.file) {
         _eTags[list.path] = eTag(list.path)!;
        }
      }
    }
  }


  ///根据文件内容生成SHA-256
  String? eTag(String path) {
    File file = File(path);
    if(!file.existsSync()) {
      return null;
    }
    var digest = md5.convert(file.readAsBytesSync());
    return digest.toString();
  }

  ///添加一个监听对象，不支持注销监听Stream
  void addListen(String path) {
    _init(path);
  }

  void close() {
    _eTags.clear();
    _onChange.close();
    _subscriptions.map((e) => e.cancel()).toList().clear();
  }
}
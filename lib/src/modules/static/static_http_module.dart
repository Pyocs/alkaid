import 'dart:io';
import 'package:alkaid/src/status/cache_control.dart';
import 'package:alkaid/src/tools/util/http_cache.dart';
import 'package:alkaid/src/tools/util/parse_regexp.dart';
import 'package:file/file.dart' as file;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../../../alkaid.dart';
import '../../core/http_context_meta.dart';
import 'process_big_file.dart';
import '../../status/alkaid_status.dart';
import '../http_module.dart';
import 'listen_file_change.dart';

///处理静态资源文件的模块
///还未实现功能 缓存(非缓存模块)、展示文件目录结构、压缩传输体积
class StaticHttpModule extends HttpModules {

  late final String _prefix ;

  final String indexFileName;

  final bool allowDirectoryListing;

  final file.FileSystem fileSystem;

  //存储下载文件的路径
  final  List<String> _downloadPath = [];
  //存储下载文件正则表达式的uri
  final List<String> _regexPath = [];

  //开启HTTP缓存的路径，支持正则表达式
  final List<RegExp> _cacheRule = [];

  // static const _fileRegExp = r"^[a-zA-Z0-9_-]+.[a-zA-Z0-9]+$";
    static const _fileRegExp = r"^(?:[a-zA-Z]:)?(?:\\/[^\\/\n]+)*[\\/]?$";
  //如果请求为目录，并且allowDirectoryListing为false,则自动将indexFileName添加到路径中
  final bool directoryAutoRetrieve;
   final ListenFileChange _listenFileChange = ListenFileChange();

  StaticHttpModule(this.fileSystem,String prefix,String modulesName,
      {this.indexFileName ='index.html',this.allowDirectoryListing = false,
        int? weight,this.directoryAutoRetrieve = true})
      :super(modulesName,weight: weight) {
    _prefix = prefix;
  }

  ///返回false表示不能处理该请求，返回true则可以
  ///不能处理请求，则由下一个节点处理
  @override
  Future<String> check(HttpRequest request,HttpResponse response) async  {
    if(request.method != 'GET' && request.method != 'HEAD') {
      throw AlkaidHttpException.notFound();
    }
    String path;
    if(indexFileName.startsWith('/')) {
      indexFileName.replaceFirst('/', '');
    }
    if(_prefix.endsWith('/')) {
      _prefix.replaceFirst(RegExp(r'\\$'), '');
    }
    if(request.uri.path == '/') {
      path ='$_prefix/$indexFileName';
    } else {
      path = '$_prefix${request.uri.path}';
    }

    if(!File(path).existsSync() && !Directory(path).existsSync()) {
      throw AlkaidHttpException.notFound();
    }
    return path;
  }

  @override
  Future handler(HttpRequest request,HttpResponse response) async {
    check(request, response).then((value) async {
        var stat = await fileSystem.stat(value);
        if(stat.type == FileSystemEntityType.directory) {
          if(allowDirectoryListing == false && directoryAutoRetrieve == true) {
           if(value.endsWith('/')) {
             value = '$value$indexFileName';
           } else {
             value = '$value/$indexFileName';
           }

           File file = File(value);
           if(File(value).existsSync()) {
             return _serveFile(request, response,file);
           } else {
             throw AlkaidHttpException.notFound();
           }
          } else if(allowDirectoryListing == true){
            return _serveDirectory(request, response, Directory(value));
          }
        } else if(stat.type == FileSystemEntityType.file) {
          return _serveFile(request, response, File(value));
        } else {
          //处理失败
          throw AlkaidHttpException.notFound();
        }
    });
  }


  Future _serveDirectory(HttpRequest request,HttpResponse response,Directory directory) async {
    response.headers.contentType = ContentType('text', 'html');
    response.write(
        '''
      <!DOCTYPE html>
      <html>
      <head><meta name="viewport" content="width=device-width,initial-scale=1">
      <style>ul { list-style-type: none; }</style>
      </head><body>
      <li><a href="..">..</a></li>
      '''
    );
    var entities = await directory.list(followLinks: false).toList().then((value) => List.from(value));
    entities.sort((a,b) {
      if(a is Directory) {
        if(b is Directory) {
          return a.path.compareTo(b.path);
        } return -1;
      } else if(a is File) {
        if(b is Directory) {
          return 1;
        }else if(b is File) {
          return a.path.compareTo(b.path);
        } return -1;
      } else if(a is Link) {
        if (b is Directory) {
          return 1;
        } else if (b is Link) {
          return a.path.compareTo(b.path);
        }
        return -1;
      }
      return 1;
    });

    for(var entity in entities) {
      String stub;
      String type;
      String uri;

      if(entity is File) {
        type = '[File]';
        stub = path.basename(entity.path);
      } else if(entity is Directory) {
        type = '[Directory]';
        stub = path.basename(entity.path);
      } else if(entity is Link) {
        type = '[Link]';
        stub = path.basename(entity.path);
      } else {
        type = '[]';
        stub = 'unknown';
      }

      uri = entity.path;
      // var href = stub;

      response.write('<li><a href="${uri.replaceAll(_prefix, '')}">$type $stub</a></li>');
    }

    response.write(r'</body></html>');
    response.close();
    return AlkaidStatus.finish;
  }

  Future _serveFile(HttpRequest request,HttpResponse response,File file) async {
    ContentType contentType;

    var type = lookupMimeType(file.path);
    if(type == null) {
      contentType = ContentType.binary;
    } else {
      var value = request.headers.value('accept');

      if(value == null || value.isEmpty  || !value.contains('*/*') && !value.contains(type) ) {
        throw AlkaidHttpException.notAcceptable();
      }
      contentType = ContentType.parse(type);
    }
    response.headers.contentType = contentType;
    if((await file.length()) / (1024 * 1024) > 50) {
      _addHeaderCache(response, file.path);
      readFileInChucks(response, file);
    } else {
      _addHeaderCache(response, file.path);
      response.add(file.readAsBytesSync());
      response.close();
    }
    //写入事件总线
    if(write) {
      write = false;
      modulesCollection.add(HttpContextMeta(request, file.readAsBytesSync()));
    }
    return AlkaidStatus.finish;
  }

  @override
  Future finish(HttpRequest request, HttpResponse response) {
    _listenFileChange.close();
    _cacheRule.clear();
    _downloadPath.clear();
    _regexPath.clear();
    return Future.value();
  }

  ///处理玩请求后有模块链调用
  @override
  Future later(HttpRequest request, HttpResponse response) {

    throw UnimplementedError();
  }

  ///提供下载功能
  ///[path]暴露的api
  ///[file] 文件(可以为文件路径，或File)
  void download(dynamic file,String path) {
    if(file is File) {
      _downloadPath.add(file.path);
    } else if(file is String) {
      if(File(file).existsSync()) {
        _downloadPath.add(file);
      } else if(Directory(file).existsSync()) {
        Directory(file).list(recursive: true).forEach((element) {
          if(element.statSync().type == FileSystemEntityType.file) {
            _downloadPath.add(element.path);
          }
        });
      }
    } else {
      return ;
    }

    AlkaidServer.getServer().routerHttpModule
      .addMethod('$path/#.*', 'GET', _downloadHandler);
    if(!path.startsWith('/')) {
      path = '/$path';
    }
    _regexPath.add('$path/#.*');
  }

  Future _downloadHandler(HttpRequest request,HttpResponse response) {
    //将请求中的文件路径解析出来
    for(int i = 0 ; i < _regexPath.length ; i++) {
      var list = parseRegExp(_regexPath[i], request.uri.path);
      if(list.isEmpty || list.length != 1) {
        continue;
      }
      if(_downloadPath.contains(list.first)) {
        File fi = File(list.first);
        if (!fi.existsSync()) {
          throw AlkaidHttpException.notFound();
        } else {
          response.headers.contentType = ContentType.binary;
          response.headers.add('Content-Disposition',
              'attachment; filename=${path.basename(fi.path)}');
          fi.openRead().pipe(response).then((_) {
            response.close();
          });
          return Future.value(AlkaidStatus.finish);
        }
      }
    }
    return Future.value(AlkaidStatus.fail);
  }

  ///对该请求路径HTTP缓存
  ///[regExp] 必须是prefix的相对路径
  void cache(String regExp,{bool file = false}) {
    RegExp reg = RegExp(regExp);
    if(!_cacheRule.contains(reg)) {
      _cacheRule.add(reg);
      //遍历当前_prefix下的所有文件，找到所有匹配的文件，生成md5
      Directory directory = Directory(_prefix);
      if(file) {
        directory.listSync(recursive: true).forEach((element) {
          if(element.statSync().type == FileSystemEntityType.file) {
            String elementPath = element.path.replaceAll(directory.path, '');
            if(elementPath.startsWith('/')) {
              elementPath = elementPath.replaceFirst('/', '');
            }
            if(reg.hasMatch(elementPath)) {
              _listenFileChange.addListen(element.path);
            }
          }
        });
      } else {
        var lists = directory.listSync(recursive: true);
        for(var element in lists) {
          if(element.statSync().type == FileSystemEntityType.directory) {
            String elementPath = element.path.replaceAll(directory.path, '');
            if(elementPath.startsWith('/')) {
              elementPath = elementPath.replaceFirst('/', '');
            }
            if(reg.hasMatch(elementPath)) {
              _listenFileChange.addListen(element.path);
              break;
            }
          }
        }
      }
    }
  }

  //向响应中添加HTTP缓存
  void _addHeaderCache(HttpResponse response,String path) {
    var value = _listenFileChange.eTage[path];
    if(value == null) {
      return ;
    }
    //缓存时间7天
    httpCache(response, CacheControl.public, 3600,length: File(path).lengthSync(),eTag: value,lastModified: File(path).lastModifiedSync());
  }

}
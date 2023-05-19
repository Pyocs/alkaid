import 'dart:io';
import 'package:file/file.dart' as file;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'process_big_file.dart';
import '../../exception/alkaid_exception.dart';
import '../../exception/alkaid_http_exception.dart';
import '../../core/modules_collection.dart';
import '../../status/alkaid_status.dart';
import '../http_module.dart';

///处理静态资源文件的模块
///还未实现功能 缓存(非缓存模块)、展示文件目录结构、压缩传输体积
class StaticHttpModule extends HttpModules {
  // final RegExp _straySlashes = RegExp(r'(^/+)|(/+$)');

  late final String _prefix ;

  final String indexFileName;

  final bool allowDirectoryListing;

  final file.FileSystem fileSystem;


  void setCollection(ModulesCollection modulesCollection) {
    this.modulesCollection = modulesCollection;
  }

  StaticHttpModule(this.fileSystem,String prefix,String modulesName,{this.indexFileName ='index.html',this.allowDirectoryListing = true,int? weight})
      :super(modulesName,weight: weight) {
    _prefix = prefix;
  }

  @override
  ///返回false表示不能处理该请求，返回true则可以
  ///不能处理请求，则由下一个节点处理
  Future check(HttpRequest request,HttpResponse response) async  {
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

    if(!File(path).existsSync()) {
      throw AlkaidHttpException.notFound();
    }

    return path;
  }

  @override
  Future handler(HttpRequest request,HttpResponse response) async {
    check(request, response).then((value) async {
      if(value is AlkaidStatus || value is AlkaidException) {
        print(value.runtimeType);
        print(value is AlkaidException);
        return AlkaidHttpException.notFound();
      } else if(value is String) {
        var stat = await fileSystem.stat(value);
        if(stat.type == FileSystemEntityType.directory) {
          return serveDirectory(request, response, Directory(value));
        } else if(stat.type == FileSystemEntityType.file) {
          return serveFile(request, response, File(value));
        } else {
          //处理失败
          throw AlkaidHttpException.notFound();
        }
      }
    });
  }


  Future serveDirectory(HttpRequest request,HttpResponse response,Directory directory) async {
    //如果不允许现实目录，返回失败
    if(!allowDirectoryListing) {
      return AlkaidStatus.fail;
    }
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

      // var href = stub;

      response.write('<li><a href="$stub">$type $stub</a></li>');
    }

    response.write(r'</body></html>');
    response.close();
    return AlkaidStatus.finish;
  }

  Future serveFile(HttpRequest request,HttpResponse response,File file) async {
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
      readFileInChucks(response, file);
    } else {
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
    // TODO: implement finish
    throw UnimplementedError();
  }

  ///处理玩请求后有模块链调用
  @override
  Future later(HttpRequest request, HttpResponse response) {
    // TODO: implement later
    throw UnimplementedError();
  }
}
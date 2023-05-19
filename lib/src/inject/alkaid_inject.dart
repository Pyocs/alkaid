import '../../alkaid.dart';
import 'controller_inject.dart';
import 'package:yaml/yaml.dart';
import 'dart:io';
import 'dart:mirrors';
import 'request_method_inject.dart';

class AlkaidInject {
  late final RouterHttpModule routerHttpModules;

  AlkaidInject(this.routerHttpModules);

  Future<void> start() async {
    final directory = Directory('lib');
    YamlMap yamlMap = loadYaml(File('pubspec.yaml').readAsStringSync());
    String packageName = yamlMap['name'];
    final uris = <Uri>[];

    await for(var entity in directory.list(recursive: true,followLinks: false)) {
      if(entity is File && entity.path.contains('.dart')) {
        // print(entity.path);
        uris.add(Uri.parse('package:$packageName${entity.path.replaceAll('lib', '')}'));
      }
    }

    IsolateMirror isolateMirror = currentMirrorSystem().isolate;

    for(var uri in uris) {
      LibraryMirror libraryMirror = await isolateMirror.loadUri(uri);
      controllerScan(routerHttpModules, libraryMirror);
      methodScan(routerHttpModules, libraryMirror);
    }
  }
}

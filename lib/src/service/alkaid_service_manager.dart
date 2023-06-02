import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:mirrors';
import '../modules.dart';
import '../annotation/request_method_annotation.dart';
import '../exception/alkaid_server_exception.dart';
import '../modules/route/route_meta.dart';
import 'alkaid_service.dart';


/**
 *  服务管理 所有的服务都由AlkaidServiceManager统一注册、管理
 *  需要使用服务的地方需要使用@Service注解，服务管理器会统一注入
 */

///控制器
///扫描接口，自动注入
///专门用来挂载AlkaidExposeService的控制器
class AlkaidServiceManager  {
  late final HashMap<String,AlkaidService> _services = HashMap();

  late final RouterHttpModule _routerHttpModules;

  //储存ExposeService的自定义API
  //只有当调用addRoute方法时会初始化，如果没有addRoute但是removeRoute会跑出异常
  //Map<String,String> => path:method
  HashMap<AlkaidExposeService,Map<String,String>>? _routes;

  final RegExp _regExp =  RegExp(r'\d+$');

  AlkaidServiceManager(RouterHttpModule routerHttpModules) : _routerHttpModules = routerHttpModules;


  ///注入后会自动挂载服务
  void inject(dynamic value) {
    _inject(reflect(value).type, reflect(value));
  }

  ///挂载一个服务
  ///[service] 需要挂载的服务
  ///[owner] 如果暴露的API需要加上控制器，则owner传入this(控制器类)
  void mount(AlkaidService service,{dynamic owner}) {
    _services[service.name] = service;
    if(service is AlkaidExposeService) {
      _processExposeService(service,owner: owner);
    }

  }

  ///卸载所有服务
  void unmountAll() {
    for(var service in _services.values) {
      if(service is AlkaidExposeService) {
        _processExposeService(service, umount: true);
      }
      service.close();
    }
    _services.clear();
  }

  ///卸载服务
  ///[name] 需要卸载的服务名称
  void unmount(String name) {
    AlkaidService? alkaidService = _services[name];
    if(alkaidService != null) {
      if(alkaidService is AlkaidExposeService) {
        _processExposeService(alkaidService,umount: true);
      }
      alkaidService.close();
      _services.remove(name);
    }
  }

  ///获取一个服务
  ///[name] 服务名称
  AlkaidService? getService(String name) {
    return _services[name];
  }


  ///扫描带有@Service注解的变量进行注入
  ///[classMirror] 需要注入的类
  ///[instanceMirror] 需要注入的类的实例
  void _inject(ClassMirror classMirror,InstanceMirror instanceMirror ) {
    classMirror.declarations.forEach((symbol, declaration) {
      //该变量包含@Service注解
      if(declaration is VariableMirror && declaration.metadata.any((element) => element.reflectee is Service)) {
        //service注解
        Service service = declaration.metadata.firstWhere((element) => element.reflectee is Service).reflectee;

        //该service的类型
        TypeMirror type = declaration.type;

        AlkaidService? alkaidService;

        TypeMirror exposeType = reflectType(AlkaidExposeService);
        TypeMirror internalType = reflectType(AlkaidInternalService);

        //单例模式
        if(service.single == null || service.single! == true) {
          //如果_services中包含该service,则直接注入
          for(var ele in _services.values) {
            if(ele.runtimeType == type.reflectedType) {
              alkaidService = ele;
              break;
            }
          }

          //为空，表明_services中没有该实例，手动创建一个实例后添加到_services中
          if(alkaidService == null) {
            //服务名称
            String name;

            if(service.name != null) {
              name = service.name!;
            } else {
              name = MirrorSystem.getName(type.simpleName);
            }

            if(type.isAssignableTo(exposeType)) {
              //构造器参数： name expose
              alkaidService = reflectClass(type.reflectedType).newInstance(Symbol(''), [name,service.expose == null ? true:service.expose!]).reflectee;
            } else if(type.isAssignableTo(internalType)) {
              alkaidService = reflectClass(type.reflectedType).newInstance(Symbol(''), [name]).reflectee;
            } else {
              throw AlkaidServerException('服务类型必须为AlkaidExposeService或AlkaidInternalService');
            }
          }
          instanceMirror.setField(symbol, alkaidService);
          if(service.controller != null && service.controller == true) {
            mount(alkaidService!,owner: instanceMirror.reflectee);
          } else {
            mount(alkaidService!);
          }
        }
        //不是用单例模式，直接创建
        else {
          AlkaidService alkaidService;
          String name;

          if(service.name != null) {
            name = service.name!;
          } else {
            name = MirrorSystem.getName(type.simpleName);
          }

          if(type.reflectedType is AlkaidExposeService) {
            //构造器参数： name expose
            alkaidService = reflectClass(type.reflectedType).newInstance(Symbol(''), [name,service.expose == null ? true:service.expose!]).reflectee;
          } else if(type.reflectedType is AlkaidInternalService) {
            alkaidService = reflectClass(type.reflectedType).newInstance(Symbol(''), [name]).reflectee;
          } else {
            throw AlkaidServerException('服务类型必须为AlkaidExposeService或AlkaidInternalService');
          }
          instanceMirror.setField(symbol, alkaidService);
          //加入缓存,如果有重名的，则会替换原有的Service
          _services.addEntries({name:alkaidService}.entries);
          if(service.controller != null && service.controller == true) {
            mount(alkaidService,owner: instanceMirror.type);
          } else {
            mount(alkaidService);
          }
        }
      }
    });
  }


  ///处理ExposeService
  ///HttpRequest给AlkaidExposeService的accept方法处理请求参数param,根据请求方法名选择处理参数的函数
  ///
  ///如果expose为true,则将service的方法暴露为API
  ///GET /serviceName => read
  ///POST /serviceName => add
  ///PATCH /serviceName => modify
  ///DELETE /serviceName => remove
  void _processExposeService(AlkaidExposeService alkaidExposeService,{bool? umount,dynamic owner}) {
    InstanceMirror instanceMirror = reflect(alkaidExposeService);

    //如果expose为false,则跳过该服务
    bool expose = instanceMirror.getField(Symbol('expose')).reflectee as bool;
    if(!expose) {
      return ;
    }

    Controller? controller;

    //请求路径
    String path;

    //如果需要处理@Controller
    //获取service的owner 如果为Class,则扫描它的注解
    //如果注解中包含@Controller ,则处理该注解
    if(owner != null) {
      ClassMirror ownerMirror = reflect(owner).type;
      for(var meta in ownerMirror.metadata) {
        if(meta.reflectee is Controller) {
          controller = meta.reflectee;
          break;
        }
      }
    }


    //获取控制器中的path
    if(controller != null) {
      path = '${controller.path}/${alkaidExposeService.name}';
    } else {
      path = '/${alkaidExposeService.name}';
    }

    if(umount == null || umount == false) {
      _addServiceMethod(path, alkaidExposeService);
      _listenExposeService(alkaidExposeService);
    } else {
      _removeServiceMethod(path);
      _cleanExposeServiceMethod(alkaidExposeService);
      // alkaidExposeService.close();
    }
  }

  //给service方法映暴露为API
  void _addServiceMethod(String path,AlkaidExposeService alkaidExposeService) {
    _routerHttpModules.get(path, alkaidExposeService.accept);
    _routerHttpModules.post(path,alkaidExposeService.accept);
    _routerHttpModules.delete(path,alkaidExposeService.accept);
    _routerHttpModules.addMethod(path, 'PATCH',alkaidExposeService.accept);
    _routes ??= HashMap();
    if(_routes![alkaidExposeService] == null) {
      _routes![alkaidExposeService] = {};
    }
    int i = 0;
    _routes![alkaidExposeService]!.addEntries({
      '$path${i++}':"GET",
      '$path${i++}':"POST",
      '$path${i++}':"DELETE",
      '$path${i++}':"PATCH",
    }.entries);

  }

  //删除服务API
  void _removeServiceMethod(String path) {
    _routerHttpModules.removeMethod(path);
  }

  //监听AlkaidExposeService是否添加或删除了路由
  void _listenExposeService(AlkaidExposeService alkaidExposeService)  {
    late StreamSubscription streamSubscription;
    streamSubscription = alkaidExposeService.stream()!.listen((event) async {
      event as Map<String,Map<String,RouterMeta?>?>;
      if(event.keys.first == 'add') {
        _routes ??= HashMap();
        if(_routes![alkaidExposeService] == null) {
          _routes![alkaidExposeService] = {
            event['add']!.keys.first:event['add']!.values.first!.method
          };
        } else {
          _routes![alkaidExposeService]!.addEntries({
            event['add']!.keys.first: event['add']!.values.first!.method
          }.entries);
        }
        _routerHttpModules.addMethod(event['add']!.keys.first,
            event['add']!.values.first!.method, event['add']!.values.first!.handlerRequest);

      } else if(event.keys.first == 'delete') {
        if(_routes == null) {
          throw AlkaidServerException('AlkaidExposeService没有添加路由!');
        }
        _routes!.removeWhere((key, value) {
          return key == alkaidExposeService &&
              value[event['delete']!.keys.first.split('_')[0]] != null &&
              value[event['delete']!.keys.first.split('_')[0]] == event['delete']!.keys.first.split('_')[1];
        });

        _routerHttpModules.removeMethod(
            event['delete']!.keys.first.split('_')[0],
            method: event['delete']!.keys.first.split('_')[1]
        );
      } else if(event.keys.first == 'done') {
        await streamSubscription.cancel();
      }
    });
  }

  //卸载服务时，将该服务自定义的API方法删除
  void _cleanExposeServiceMethod(AlkaidExposeService alkaidExposeService) {
    if(_routes == null) {
      return ;
    }

    var methods = _routes![alkaidExposeService];
    //没有需要删除的方法
    if(methods == null) {
      return ;
    }
    methods.forEach((path, method) {
      _routerHttpModules.removeMethod(path,method: method);
    });
    _routes!.remove(alkaidExposeService);
  }

  ///服务跳转,如果没有该服务，则跑出异常
  ///[name] 服务名称
  Future jump(String name,HttpRequest request,HttpResponse response) {
    AlkaidService? alkaidService = getService(name);
    if(alkaidService == null) {
      throw AlkaidServerException('没有$name服务');
    } else {
      return alkaidService.accept(request, response);
    }
  }


  ///给指定AlkaidExposeService的API添加拦截方法(服务的accept方法)
  ///[name] 服务名称
  ///[path] 请求路径
  ///[method] 请求方法
  ///[handRequest] 拦截方法
  ///[before] 默认before,否则为after
  void intercept(String name,String path,String method,HandlerRequest handlerRequest,bool before) {
    AlkaidService? alkaidService = _services[name];
    if(alkaidService == null) {
      throw AlkaidServerException('没有$name服务!');
    }
    if(alkaidService is AlkaidInternalService) {
      throw AlkaidServerException('$name服务为InternalService!');
    }

    alkaidService as AlkaidExposeService;
    if(!alkaidService.expose) {
      throw AlkaidServerException('$name服务没有暴露!');
    }

    assert(_routes != null && _routes![alkaidService] != null,"该服务没有自定义API!");


    if(before) {
      _routerHttpModules.before(path, method, handlerRequest);
    } else {
      _routerHttpModules.after(path, method, handlerRequest);
    }
  }

  ///将指定Expose服务的所有API添加handlerRequest拦截方法
  void interceptAll(String name,HandlerRequest handlerRequest,bool before) {
    AlkaidService? alkaidService = _services[name];
    if(alkaidService == null) {
      throw AlkaidServerException('没有$name服务!');
    }
    if(alkaidService is AlkaidInternalService) {
      throw AlkaidServerException('$name服务为InternalService!');
    }

    alkaidService as AlkaidExposeService;
    if(!alkaidService.expose) {
      throw AlkaidServerException('$name服务没有暴露!');
    }

    _routes![alkaidService]!.forEach((key, value) {
      if(key.contains(_regExp)) {
        key = key.substring(0,key.indexOf(_regExp));
      }
      if(before) {
        _routerHttpModules.before(key, value, handlerRequest);
      } else {
        _routerHttpModules.after(key, value, handlerRequest);
      }
    });
  }


}


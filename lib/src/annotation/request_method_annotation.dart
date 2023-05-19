///控制器中的所有处理方法path前都会自动添加path
class Controller{
  final String path;

  const Controller({this.path = ''});
}

///依赖注入服务
class Service {
  final String? name;

  ///是否为单例，null表示为true,false则会创建新的对象
  final bool? single;

  ///是否暴露为API(需要为AlkaidExposeService才能暴露)
  final bool? expose;

  ///是否处理控制器
  final bool? controller;

  ///默认使用同名注册
  const Service({this.name,this.single,this.expose,this.controller});
}

class API{
  ///请求方法
  final String method;

  ///请求路径
  final String path;

  const API(this.method,this.path);
}

class GET extends API{
  const GET(String path) : super('GET',path);
}

class POST extends API{
  const POST(String path) : super('POST',path);
}

class PUT extends API{
  const PUT(String path) : super('PUT',path);
}

class DELETE extends API{
  const DELETE(String path) : super('DELETE',path);
}
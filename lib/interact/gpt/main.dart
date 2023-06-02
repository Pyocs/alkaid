import 'dart:io';
import 'package:alkaid/alkaid.dart';

///编写处理方法
///编写控制器
///编写服务

///AI写完请求方法后需要测试才能添加到现有的代码中,如何测试？，以及如何添加？
///测试判断输出是否达到预期结果，如何将请求、响应输入呢？需要在AlkaidServer创立隔离区
///新建一个RouteHttpModule,名字命名为test,将该模块接收到的请求封装后发送给AI写好的处理方法
///如何将测试好的处理方法添加到现有的代码中？需要指定写入的文件目录
///
///让AI编写服务，首先让AI了解你的项目，你编写服务的具体功能，以及服务的类型(Expose?)
/// 其次服务是依赖与控制器的，将需要的服务写完后，因该将服务集成到控制器中，再进行测试，写入文件等操作

class A {

  @Service(name: 'list',expose: true,controller: true,single: false)
  late final AlkaidListService alkaidListService;


  addStudent(HttpRequest request,HttpResponse response) {

  }
}
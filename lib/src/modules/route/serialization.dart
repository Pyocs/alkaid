import 'dart:io';

///响应序列化方式

abstract class Serialization {
  ///序列化结果
  dynamic serial(dynamic value);
}
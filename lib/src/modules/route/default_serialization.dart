import 'dart:io';
import 'package:alkaid/src/modules/route/serialization.dart';

class DefaultSerialization extends Serialization {
  @override
  serial(value) {
    return value.toString();
  }
}
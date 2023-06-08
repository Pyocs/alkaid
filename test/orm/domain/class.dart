import 'package:alkaid/alkaid.dart';

@Table('class_inf',order: 1)
class Class  {

  @Row('int', 'class_id',constraint:[PRIMARY(),AUTOINCREMENT(),NOTNULL()])
  late int classId;
  
  @Row('varchar(30)', 'class_name',constraint:[])
  late String? className;
  
  @Row('int', 'spe_id',constraint:[NOTNULL()])
  late int speId;
  
  Class();

  Class.intact(this.classId,this.className,this.speId);

  @override
  String toString() {
        return " classId:$classId  className:$className  speId:$speId \n";
  }

}

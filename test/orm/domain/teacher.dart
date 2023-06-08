import 'package:alkaid/alkaid.dart';

@Table('teacher_inf',order: 1)
class Teacher  {

  @Row('int', 'teacher_id',constraint:[PRIMARY(),AUTOINCREMENT(),NOTNULL()])
  late int teacherId;
  
  @Row('varchar(20)', 'teacher_name',constraint:[NOTNULL()])
  late String teacherName;
  
  @Row('int', 'teacher_role_id',constraint:[NOTNULL()])
  late int teacherRoleId;
  
  Teacher();

  Teacher.intact(this.teacherId,this.teacherName,this.teacherRoleId);

  @override
  String toString() {
        return " teacherId:$teacherId  teacherName:$teacherName  teacherRoleId:$teacherRoleId \n";
  }

}

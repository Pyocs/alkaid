import 'package:alkaid/alkaid.dart';

@Table('course_inf',order: 1)
class Course  {

  @Row('int', 'course_id',constraint:[NOTNULL(),PRIMARY(),AUTOINCREMENT()])
  late int courseId;
  
  @Row('varchar(30)', 'course_name',constraint:[])
  late String? courseName;
  
  @Row('int', 'teacher_id',constraint:[NOTNULL()])
  late int teacherId;
  
  @Row('int', 'class_id',constraint:[NOTNULL()])
  late int classId;
  
  Course();

  Course.intact(this.courseId,this.courseName,this.teacherId,this.classId);

  @override
  String toString() {
        return " courseId:$courseId  courseName:$courseName  teacherId:$teacherId  classId:$classId \n";
  }

}

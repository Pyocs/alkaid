import 'package:alkaid/alkaid.dart';

@Table('score_inf',order: 1)
class Score  {

  @Row('int', 'student_id',constraint:[NOTNULL()])
  late int studentId;
  
  @Row('int', 'course_id',constraint:[NOTNULL()])
  late int courseId;
  
  Score();

  Score.intact(this.studentId,this.courseId);

  @override
  String toString() {
        return " studentId:$studentId  courseId:$courseId \n";
  }

}

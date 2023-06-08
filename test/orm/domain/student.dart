import 'package:alkaid/alkaid.dart';

@Table('student_inf',order: 1)
class Student  {

  @Row('int', 'student_id',constraint:[PRIMARY(),AUTOINCREMENT(),NOTNULL()])
  late int studentId;
  
  @Row('varchar(20)', 'student_name',constraint:[NOTNULL()])
  late String studentName;
  
  @Row('enum("男", "女")', 'student_sex',constraint:[])
  late dynamic studentSex;
  
  @Row('timestamp', 'student_birthday',constraint:[])
  late DateTime? studentBirthday;
  
  @Row('varchar(11)', 'student_del',constraint:[])
  late String? studentDel;
  
  @Row('varchar(30)', 'student_native',constraint:[])
  late String? studentNative;
  
  @Row('int', 'class_id',constraint:[])
  late int? classId;
  
  Student();

  Student.intact(this.studentId,this.studentName,this.studentSex,this.studentBirthday,this.studentDel,this.studentNative,this.classId);

  @override
  String toString() {
        return " studentId:$studentId  studentName:$studentName  studentSex:$studentSex  studentBirthday:$studentBirthday  studentDel:$studentDel  studentNative:$studentNative  classId:$classId \n";
  }

}

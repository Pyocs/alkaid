import 'package:alkaid/alkaid.dart';

@Table('school_inf',order: 1)
class School  {

  @Row('int', 'school_id',constraint:[PRIMARY(),AUTOINCREMENT(),NOTNULL()])
  late int schoolId;
  
  @Row('varchar(30)', 'school_name',constraint:[NOTNULL()])
  late String schoolName;
  
  @Row('varchar(255)', 'school_address',constraint:[])
  late String? schoolAddress;
  
  @Row('varchar(255)', 'city_name',constraint:[])
  late String? cityName;
  
  School();

  School.intact(this.schoolId,this.schoolName,this.schoolAddress,this.cityName);

  @override
  String toString() {
        return " schoolId:$schoolId  schoolName:$schoolName  schoolAddress:$schoolAddress  cityName:$cityName \n";
  }

}

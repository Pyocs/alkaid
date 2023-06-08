import 'package:alkaid/alkaid.dart';

@Table('role_inf',order: 1)
class Role  {

  @Row('int', 'role_id',constraint:[PRIMARY(),AUTOINCREMENT(),NOTNULL()])
  late int roleId;
  
  @Row('varchar(30)', 'role_name',constraint:[])
  late String? roleName;
  
  Role();

  Role.intact(this.roleId,this.roleName);

  @override
  String toString() {
        return " roleId:$roleId  roleName:$roleName \n";
  }

}

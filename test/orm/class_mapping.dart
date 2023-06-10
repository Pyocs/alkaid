import 'package:alkaid/alkaid.dart';
import 'domain/class.dart';

@ORM()
abstract class ClassMapping {

  @Insert("insert into class_inf values(null,?,?)")
  Future<dynamic> insertClass(Class c);

  @Insert('insert into class_inf(class_name,spe_id) values(?,?)')
  Future<dynamic> insert2(Class c);

  @Insert('insert into class_inf(class_name,spe_id) values(?,?)',resultSet: true)
  Future<dynamic> insert3(String name,int id);

  @Delete("delete from class_inf where class_id = ?")
  Future<dynamic> deleteClassById(int id);

  @Delete('delete from class_inf where class_name = ?')
  Future<dynamic> deleteClassByName(String name);

  @Delete('delete from class_inf where spe_id = ?')
  Future<dynamic> deleteClassBySpeId(int id);

  @Delete('delete from class_inf where class_id = ? and class_name = ? and spe_id = ?')
  Future<dynamic> deleteClass(Class c);

  @Update("update class_inf set class_name = ? where class_id = ?")
  Future<dynamic> updateClassName(Class c);

  //修改班级专业
  @Update("update class_inf set spe_id = ? where class_name = ?")
  Future<dynamic> updateClassSpe(Class c);

  @Update('update class_inf set class_name = ? where class_id = ?')
  Future<dynamic> updateClassNameById(String name,int id);

  @Select('select * from class_inf', Class)
  Future<dynamic> getAllClass();

  @Select('select * from class_inf where class_id = ?', Class)
  Future<dynamic> getClassById(int id);
  
  @Select('select class_id,class_name,spe_id from class_inf where spe_id = ?', Class)
  Future<dynamic> getClassBySpeId(int id);

  Future<void> startTransaction();
  Future<void> commit();
  Future<void> rollback();
  Future<void> savepoint(String name);
  Future<void> rollbackTo(String name);
  Future<void> startAutocommit();
  Future<void> closeAutocommit();
  bool isAutocommit();
  Future<void> close();
}
 
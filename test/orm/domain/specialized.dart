import 'package:alkaid/alkaid.dart';

@Table('specialized_inf',order: 1)
class Specialized  {

  @Row('int', 'spe_id',constraint:[PRIMARY(),NOTNULL(),AUTOINCREMENT()])
  late int speId;
  
  @Row('varchar(40)', 'spe_name',constraint:[NOTNULL()])
  late String speName;
  
  Specialized();

  Specialized.intact(this.speId,this.speName);

  @override
  String toString() {
        return " speId:$speId  speName:$speName \n";
  }

}

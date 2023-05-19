
///定义一个表
class Table {
  //指定表的生成顺序
  final int? order;
  final String tableName;
  const Table(this.tableName,{this.order});
}

///定义表中的行
class Row {
  ///行名
  final String rowName;

  ///数据类型
  final String type;

  ///约束
  final List<dynamic>? constraint;

  const Row(this.type,this.rowName,{this.constraint});
}

///约束
class PRIMARY {
  const PRIMARY();
}

class FOREIGN {
  //外连接的表名
  final String tableName;

  //外连接的字段
  final String field;
  const FOREIGN(this.tableName,this.field);
}

class NOTNULL {
  const NOTNULL();
}

class UNIQUE {
  const UNIQUE();
}

class DEFAULT{
  final String value;
  const DEFAULT(this.value);
}

class AUTOINCREMENT {
  const AUTOINCREMENT();
}

class Insert {
  final String sql;

  ///为true时将返回IResultSet
  ///为false 或 null不返回
  final bool? resultSet;

  const Insert(this.sql,{this.resultSet});
}

class Update {
  final String sql;

  final bool? resultSet;

  const Update(this.sql,{this.resultSet});
}

class Delete {
  final String sql;

  final bool? resultSet;

  const Delete(this.sql,{this.resultSet});
}

class Select {
  final String sql;

  ///根据驼峰命名自动映射，false根据fields映射
  final bool autoInject;

  ///反序列花的对象列表
  final Type object;

  ///映射的字段
  final Map<String,String>? fields;

  const Select(this.sql,this.object,{this.autoInject = true,this.fields});
}

class ORM {
  const ORM();
}

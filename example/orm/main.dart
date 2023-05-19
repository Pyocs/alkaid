import 'package:mysql_client/mysql_client.dart';

import 'address_mapping.dart';

void main() async {
  MySQLConnection  mySQLConnection = await MySQLConnection.createConnection(secure:false,host: '192.168.1.127', port: 3306, userName: 'root', password: 'tan+82698',databaseName: 'mybatis');
  await mySQLConnection.connect();
  AddressMapping addressMapping = AddressMappingImpl();
  print(addressMapping.getAddressById(1));
}
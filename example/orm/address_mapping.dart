import 'dart:mirrors';

import 'package:alkaid/alkaid.dart';
import 'package:alkaid/src/orm/alkaid_orm.dart';
import 'address.dart';

@ORM()
abstract class AddressMapping {
  @Select('''	select a.*, p.*
      from address_inf a
      join person_address pa
      on a.addr_id = pa.address_id
      join person_inf p
      on pa.owner_id = p.person_id
      where addr_id = ? ''', Address)
  Future<dynamic> getAddressById(int id);
}


class AddressMappingImpl  with AlkaidORM implements AddressMapping  {
@override
dynamic noSuchMethod(Invocation invocation) async {
  var owner = reflectClass(AddressMapping);
  for (var element in owner.declarations[invocation.memberName]!.metadata) {
    switch(element.reflectee.runtimeType) {
      case(Select):
        Select select = element.reflectee;
        return await selectMixin(select, invocation.positionalArguments);
      case(Insert):
        Insert insert = element.reflectee;
        return insertMixin(insert, invocation.positionalArguments);
      case(Update):
        Update update = element.reflectee;
        return updateMixin(update, invocation.positionalArguments);
      case(Delete):
        Delete delete = element.reflectee;
        return deleteMixin(delete, invocation.positionalArguments);
    }
  }
}

}
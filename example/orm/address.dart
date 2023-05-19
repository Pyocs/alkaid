class Address {
  late int? addrId;

  late String addrDetail;

  List<Owner> owners = [];

  Address();

  @override
  String toString() {
    return 'id:$addrId  detail:$addrDetail   owners:$owners\n';
  }
}

class Owner {
  late int ownerId;

  late int addressId;

  Owner();

  @override
  String toString() {
    // TODO: implement toString
    return "ownerId:$ownerId  address:$addressId \n";
  }
}
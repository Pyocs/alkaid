class DatabaseConfig {
  final String _name;

  String get name => _name;

  final String _host;

  String get host => _host;

  final int _port;

  int get port => _port;

  final String _user;

  String get user => _user;

  final String _password;

  String get password => _password;

  bool? _secure;

  bool? get secure => _secure;

  late final String? _databaseName;

  String? get databaseName => _databaseName;

  late final String collation;

  DatabaseConfig({
    required String name,
    required String host,
    required int port,
    required String user,
    required String password,
    String? databaseName,
    bool? secure,
    String? collation
  }) : _name = name,_host = host,_port = port, _user = user,_password = password {
    if(secure == null) {
      _secure = true;
    } else {
      _secure = secure;
    }

    if(collation == null) {
      collation = 'utf8mb5_general_ci';
    }  else {
      this.collation = collation;
    }
    _databaseName = databaseName;
  }

}
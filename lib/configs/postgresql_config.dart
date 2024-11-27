import 'package:dart_net_core_api/config.dart';

class PostgreSQLConfig implements IConfig {
  String? user;
  String? password;
  String? host;
  int? port;
  String? database;
  String? localDataPath;

  
  String get connectionString {
    return 'postgres://$user:$password@$host:$port/$database';
  }
}
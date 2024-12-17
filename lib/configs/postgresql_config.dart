import 'package:dart_net_core_api/exports.dart';

@SnakeToCamel()
class PostgreSQLConfig implements IConfig {
  String? user;
  String? password;
  String? host;
  int? port;
  String? database;
  String? localDataPath;
  bool? isSecureConnection;
  bool? printQueries;

  bool get isValid {
    return user?.isNotEmpty == true &&
        password != null &&
        host?.isNotEmpty == true &&
        port != null &&
        database?.isNotEmpty == true;
  }

  String get connectionString {
    return 'postgres://$user:$password@$host:$port/$database';
  }
}

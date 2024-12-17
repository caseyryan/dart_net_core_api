import 'package:dart_net_core_api/exports.dart';

@SnakeToCamel()
class MongoConfig implements IConfig {
  String? connectionString;
  bool? isSecure;
}
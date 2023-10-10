import 'package:dart_net_core_api/database/configs/mongo_config.dart';
import 'package:dart_net_core_api/database/configs/mysql_config.dart';
import 'package:dart_net_core_api/database/configs/postgresql_config.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';

/// all custom configurations must implement this interface
/// This is necessary because an instance of config will 
/// be passed to every service you initialize
abstract class IConfig {}


/// The most basic configurations that can accept typical configs
/// 
/// You can implement completely custom configuration
/// there is no need to use this one
class Config implements IConfig {
  JwtConfig? jwtConfig;
  MongoConfig? mongoConfig;
  MysqlConfig? mysqlConfig;
  PostgreSQLConfig? postgreSQLConfig;
}
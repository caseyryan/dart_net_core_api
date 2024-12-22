import 'dart:io';

import 'package:dart_net_core_api/configs/mongo_config.dart';
import 'package:dart_net_core_api/configs/mysql_config.dart';
import 'package:dart_net_core_api/configs/password_hash_config.dart';
import 'package:dart_net_core_api/configs/postgresql_config.dart';
import 'package:dart_net_core_api/exceptions/api_exceptions.dart';
import 'package:dart_net_core_api/exports.dart';
import 'package:dart_net_core_api/jwt/config/jwt_config.dart';

import 'default_setups/configs/failed_password_config.dart';

/// all custom configurations must implement this interface
/// This is necessary because an instance of config will
/// be passed to every service you initialize and it's determined by
/// the interface
///
abstract class IConfig {}

/// The most basic configurations that can accept typical configs
///
/// You can implement completely custom configuration
/// there is no need to use this one
///
/// In your JSON config you may specify the direct value for each key
/// or you can use strings like "$PASSWORD_SALT" prefixed with a dollar
/// sign this will be evaluated as the environment variable called
/// PASSWORD_SALT. If the variable is not set you will get an exception
///
/// Another way to set values is to use "$ENV" or "$env" (lowercase)
/// in this case it will use the key from your json as the name of the environment variable
/// first converting it to uppercase
/// for example you set it like this:
/// {
///    "password_salt": "$ENV"
/// }
/// the parser will try to find the environment variable called "PASSWORD_SALT" (uppercase)
/// because the $ENV is uppercase, and if you do it like this
/// {
///   "password_salt": "$env"
/// }
/// it will try to find the environment variable called "password_salt" (lowercase)

/// It's very important to have an explicit Json Key NameConverter here
/// because the config is always camel case but you might use default
/// converter that uses snake case, and because of that the config will not be
/// parsed correctly.
@SnakeToCamel()
class Config implements IConfig {
  JwtConfig? jwtConfig;
  MongoConfig? mongoConfig;
  MysqlConfig? mysqlConfig;
  PostgreSQLConfig? postgreSQLConfig;
  String? usedDbConfig;
  SocketConfig? socketConfig;
  PasswordHashConfig? passwordHashConfig;
  FailedPasswordConfig? failedPasswordConfig;
  bool printDebugInfo = true;
  StaticFileConfig? staticFileConfig;
  AccessControlConfig? accessControlHeaders;
  int? maxUploadFileSizeBytes;
  int? httpPort;
  int? httpsPort;

  Directory? get staticFileDirectory {
    Directory dir;
    if (staticFileConfig?.isAbsolute == null) {
      return null;
    }
    if (staticFileConfig!.isAbsolute) {
      dir = Directory('${staticFileConfig?.staticFilesRoot}');
    } else {
      dir = Directory('${Directory.current.path}/${staticFileConfig?.staticFilesRoot}');
    }
    if (!dir.existsSync()) {
      throw NotFoundException(
        message: 'Static files directory `${dir.path}` does not exist. You must create it manually',
      );
    }
    return dir;
  }
  
  Directory? get tempFilesRoot {
    Directory dir;
    if (staticFileConfig?.isAbsolute == null) {
      return null;
    }
    if (staticFileConfig!.isAbsolute) {
      dir = Directory('${staticFileConfig?.tempFilesRoot}');
    } else {
      dir = Directory('${Directory.current.path}/${staticFileConfig?.tempFilesRoot}');
    }
    if (!dir.existsSync()) {
      throw NotFoundException(
        message: 'Temp files directory `${dir.path}` does not exist. You must create it manually',
      );
    }
    return dir;
  }
}

@SnakeToCamel()
class StaticFileConfig implements IConfig {
  /// if true, it will not prepend current working directory
  bool isAbsolute = false;
  String? staticFilesRoot;
  String? tempFilesRoot;
}

@SnakeToCamel()
class AccessControlConfig implements IConfig {
  String? allowOrigin;
  String? allowMethods;
  String? allowHeaders;
  int? maxAge;
}

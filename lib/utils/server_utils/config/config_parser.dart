import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:dart_core_orm/dart_core_orm.dart';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/configs/postgresql_config.dart';
import 'package:dart_net_core_api/server.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:logging/logging.dart';
import 'package:reflect_buddy/reflect_buddy.dart';
import 'package:yaml/yaml.dart';

import '../../../config.dart';

/// You can extend this config to make a custom one
/// or write absolutely new class if you don't need any of these
class ConfigParser {
  /// [configPath] an optional path to a json config.
  /// The file configs like this have the lowest priority
  /// if you have set environment variables with the needed
  /// values it will use them instead of the values from the file.
  /// If none are provided, the default values will be used instead
  /// [isAbsolutePath] if false, the [configPath] will be searched for
  /// relatively to the current working directory
  ConfigParser({
    required Type configType,
    String? configPath,
    bool isAbsolutePath = false,
    required IServer server,
  }) : _server = server {
    if (!configType.implementsInterface<IConfig>()) {
      throw 'All configurations must implement $IConfig interface';
    }

    /// the lowest priority is the config from map
    /// after it's parsed (or even if the map is missing)
    /// the server will then try to fill the values from the
    /// environment variables.
    if (configPath != null) {
      String fullPath;
      final currentPath = Directory.current.path;
      if (!isAbsolutePath) {
        fullPath = Directory('$currentPath/$configPath').path;
      } else {
        fullPath = configPath;
      }
      final configFile = File(fullPath);
      if (configFile.existsSync()) {
        Map? configJson;
        final fileContents = configFile.readAsStringSync();
        if (configFile.path.toLowerCase().endsWith('.json')) {
          configJson = jsonDecode(
            fileContents,
          );
        } else if (configFile.path.toLowerCase().endsWith('.yaml')) {
          configJson = loadYaml(fileContents) as Map;
        }
        if (configJson == null) {
          throw 'The config file was not found at $configPath. Even though the path was specified';
        }
        _trySetValuesFromEnvironmentVariables(configJson);
        _configInstance = configType.fromJson(configJson) as IConfig;
      } else {
        Logger.root.log(
          Level.SEVERE,
          'The config file was not found at $configPath. Even though the path was specified',
        );
        throw 'The config file was not found at $configPath. Even though the path was specified';
      }
    }

    /// Searches all inner fields and tries to collect all that belong to
    /// IConfig. This is required to simplify a later search for configs from
    /// inside Service objects
    /// e.g. You have a config of type JwtConfig inside the _configInstance
    /// you don't have to get it using  config.jwtConfig but instead you can
    /// directly get it using httpContext.getConfig<JwtConfig>() in any of your controllers
    _allConfigs.addAll(
      _configInstance!.findAllInstancesOfType<IConfig>(),
    );
    _initDatabases();
  }

  /// Not sure if it's a best place to init databases. But I kept it for now
  void _initDatabases() {
    final config = getConfig<Config>();
    if (config?.usedDbConfig == 'postgresqlConfig') {
      final postgresqlConfig = getConfig<PostgreSQLConfig>();
      if (postgresqlConfig?.isValid == true) {
        /// reflect_buddy setting
        alwaysIncludeParentFields = true;
        final bool useCamelCase = _server.settings.jsonSerializer?.keyNameConverter is SnakeToCamel;
        /// what this actually does is only creating a settings object.
        /// It doesn't create a database or a table.
        Orm.initialize(
          database: postgresqlConfig!.database!,
          username: postgresqlConfig.user!,
          password: postgresqlConfig.password!,
          host: postgresqlConfig.host!,
          family: ORMDatabaseFamily.postgres,
          isSecureConnection: postgresqlConfig.isSecureConnection == true,
          printQueries: postgresqlConfig.printQueries == true,
          port: postgresqlConfig.port!,
          /// if true postgres will use double quotes for column and table names
          useCaseSensitiveNames: useCamelCase,
        );
      }
    }
  }

  /// tries to to set values from environment
  void _trySetValuesFromEnvironmentVariables(Map data) {
    final Map<String, String> envVariables = Platform.environment;
    for (var kv in data.entries) {
      if (kv.value is Map) {
        _trySetValuesFromEnvironmentVariables(kv.value as Map);
      }
      if (kv.value is String) {
        if (kv.value.startsWith(r'$')) {
          /// this means an environment variable value is expected
          String envVariableName = kv.value.substring(1);
          if (envVariableName == 'ENV') {
            envVariableName = kv.key.toUpperCase();
          } else if (envVariableName == 'env') {
            envVariableName = kv.key.toLowerCase();
          }
          final valueFromEnvironment = envVariables[envVariableName];
          if (valueFromEnvironment != null) {
            data[kv.key] = valueFromEnvironment;
          }
        }
      }
    }
  }

  final HashSet<IConfig> _allConfigs = HashSet();
  final Map<Type, IConfig> _cachedConfigs = {};
  final IServer _server;

  Object? _configInstance;

  T? getConfig<T extends IConfig>() {
    IConfig? config = _cachedConfigs[T];
    if (config != null) {
      return config as T;
    }
    if (_allConfigs.isEmpty) {
      if (_configInstance.runtimeType != T) {
        return null;
      } else {
        return _configInstance! as T;
      }
    }
    config = _allConfigs.firstWhereOrNull((e) => e is T) as T?;
    if (config != null) {
      _cachedConfigs[T] = config;
    }
    return config as T?;
  }
}

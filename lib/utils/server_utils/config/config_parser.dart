import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:reflect_buddy/reflect_buddy.dart';

import 'config.dart';

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
  }) {
    if (!configType.implementsInterface<IConfig>()) {
      throw 'All configurations must implement $IConfig interface';
    }

    if (configPath != null) {
      String fullPath;
      final currentPath = Directory.current.path;
      if (!isAbsolutePath) {
        fullPath = Directory('$currentPath/$configPath').path;
      } else {
        fullPath = configPath;
      }
      final configJson = jsonDecode(
        File(fullPath).readAsStringSync(
          encoding: utf8,
        ),
      );

      _configInstance = configType.fromJson(configJson) as IConfig;

      /// Searches all inner fields and tries to collect all that belong to
      /// IConfig. This is required to simplify a later search for configs from
      /// inside Service objects
      _allConfigs.addAll(
        _configInstance!.findAllInstancesOfType<IConfig>(),
      );
    }
  }

  final HashSet<IConfig> _allConfigs = HashSet();
  final Map<Type, IConfig> _cachedConfigs = {};

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

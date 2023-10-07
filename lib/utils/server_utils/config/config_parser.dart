import 'dart:convert';
import 'dart:io';

import 'package:reflect_buddy/reflect_buddy.dart';

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

      _configInstance = configType.fromJson(configJson);
    }
  }

  Object? _configInstance;

  T getConfig<T>() {
    return _configInstance! as T;
  }
}

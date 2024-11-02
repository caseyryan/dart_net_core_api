import 'dart:async';

import 'package:dart_net_core_api/utils/mirror_utils/extensions.dart';
import 'package:logging/logging.dart';

/// This utility might be used to quickly log data from anywhere
/// For example an annotation which required a const constructor.
/// Just call log method from any where in your app

Map<String, Logger> _loggers = {};

Logger _getLogger(String loggerName) {
  if (!_loggers.containsKey(loggerName)) {
    _loggers[loggerName] = Logger(loggerName);
  }
  return _loggers[loggerName]!;
}

extension LogExtension on Object {
  void logStackTrace(
    Object? e,
    StackTrace? s, {
    String? traceId,
  }) {
    logGlobal(
      level: Level.SEVERE,
      message: e.toString(),
      stackTrace: s,
      traceId: traceId,
    );
  }

  void logGlobal({
    required Level level,
    required Object message,
    String? traceId,
    StackTrace? stackTrace,
    Zone? zone,
  }) {
    _getLogger(toLoggerName()).log(
      level,
      traceId,
      message,
      stackTrace,
      zone,
    );
  }
}

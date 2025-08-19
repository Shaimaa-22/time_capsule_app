import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

class Logger {
  static const String _appName = 'TimeCapsule';
  static bool _isEnabled = true;
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  //  color codes for console output
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';

  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void critical(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.critical,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void auth(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: 'AUTH',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void database(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: 'DATABASE',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void ui(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag: 'UI',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void network(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: 'NETWORK',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void capsule(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: 'CAPSULE',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void performance(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag: 'PERFORMANCE',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static Future<T> logExecutionTime<T>(
    String operationName,
    Future<T> Function() operation, {
    String? tag,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      performance(
        '$operationName completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      Logger.error(
        '$operationName failed after ${stopwatch.elapsedMilliseconds}ms',
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (!_isEnabled || level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(8);
    final tagStr = tag != null ? '[$tag]' : '';
    final dataStr = data != null ? ' Data: $data' : '';
    final color = _getColorForLevel(level);

    final logMessage =
        '$color[$_appName] $timestamp $levelStr $tagStr $message$dataStr$_reset';

    if (kDebugMode) {
      print(logMessage);
    }

    developer.log(
      '$message$dataStr',
      time: DateTime.now(),
      level: _getDeveloperLogLevel(level),
      name: '$_appName${tag != null ? '.$tag' : ''}',
      error: error,
      stackTrace: stackTrace,
    );

    if (error != null) {
      final errorMessage =
          '$color[$_appName] $timestamp ERROR    $tagStr Error: $error$_reset';
      if (kDebugMode) {
        print(errorMessage);
      }
    }

    if (stackTrace != null && level.index >= LogLevel.error.index) {
      final stackMessage =
          '$color[$_appName] $timestamp STACK    $tagStr StackTrace:\n$stackTrace$_reset';
      if (kDebugMode) {
        print(stackMessage);
      }
    }
  }

  static String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _cyan;
      case LogLevel.info:
        return _green;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
      case LogLevel.critical:
        return _magenta;
    }
  }

  static int _getDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  static void lifecycle(String event, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' Data: $data' : '';
    info('App Lifecycle: $event$dataStr', tag: 'LIFECYCLE');
  }

  static void userAction(String action, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' Data: $data' : '';
    info('User Action: $action$dataStr', tag: 'USER_ACTION');
  }

  static void navigation(String route, {String? from}) {
    final fromStr = from != null ? ' from $from' : '';
    info('Navigation: $route$fromStr', tag: 'NAVIGATION');
  }

  static ClassLogger forClass(String className) {
    return ClassLogger(className);
  }
}

class ClassLogger {
  final String className;

  ClassLogger(this.className);

  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    Logger.debug(
      message,
      tag: className,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    Logger.info(
      message,
      tag: className,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    Logger.warning(
      message,
      tag: className,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    Logger.error(
      message,
      tag: className,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  void critical(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    Logger.critical(
      message,
      tag: className,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  Future<T> logExecutionTime<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return Logger.logExecutionTime(operationName, operation, tag: className);
  }
}

extension LoggerExtension on Object {
  void logDebug(String message) {
    Logger.debug(message, tag: runtimeType.toString());
  }

  void logInfo(String message) {
    Logger.info(message, tag: runtimeType.toString());
  }

  void logWarning(String message) {
    Logger.warning(message, tag: runtimeType.toString());
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    Logger.error(
      message,
      tag: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}

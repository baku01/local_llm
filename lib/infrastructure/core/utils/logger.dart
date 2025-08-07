/// Logging utility for the application.
///
/// Provides a centralized logging system that can be configured
/// for different environments (development, production, testing).
library;

import 'dart:developer' as developer;

/// Log levels for different types of messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Application logger
class AppLogger {
  static bool _isDebugMode = true;

  /// Configure logger for production mode
  static void setProductionMode() {
    _isDebugMode = false;
  }

  /// Configure logger for debug mode
  static void setDebugMode() {
    _isDebugMode = true;
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (_isDebugMode) {
      _log(LogLevel.debug, message, tag);
    }
  }

  /// Log info messages
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  /// Log warning messages
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  /// Log error messages
  static void error(String message,
      [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, tag);
    if (error != null) {
      developer.log(
        'Error details: $error',
        name: tag ?? 'AppLogger',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Internal logging method
  static void _log(LogLevel level, String message, String? tag) {
    final logTag = tag ?? 'AppLogger';
    final levelStr = level.name.toUpperCase();

    developer.log(
      '[$levelStr] $message',
      name: logTag,
      level: _getLevelValue(level),
    );
  }

  /// Get numeric level value for developer.log
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

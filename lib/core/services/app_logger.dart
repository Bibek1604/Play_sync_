import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// levels of logging
enum LogLevel { debug, info, warning, error }

/// A robust logging utility for the PlaySync app.
/// This ensures logs are visible in the console and can be captured
/// by tools like 'adb logcat' even after a debugger disconnects.
class AppLogger {
  AppLogger._();

  static const String _tag = 'PlaySync';

  /// Log a message at the DEBUG level
  static void debug(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a message at the INFO level
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log a message at the WARNING level
  static void warning(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a message at the ERROR level
  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Internal logging implementation
  static void _log(LogLevel level, String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    final effectiveTag = tag ?? _tag;
    final timestamp = DateTime.now().toIso8601String().split('T').last;
    final levelStr = level.toString().split('.').last.toUpperCase();
    
    final fullMessage = '[$timestamp] [$levelStr] [$effectiveTag] $message';

    if (kDebugMode) {
      // debugPrint is generally safer for large logs and visible in logcat
      debugPrint(fullMessage);
      
      if (error != null) {
        debugPrint('  Error: $error');
      }
      
      if (stackTrace != null && level == LogLevel.error) {
        debugPrint('  StackTrace: $stackTrace');
      }
      
      // Also log to Dart Developer console for DevTools
      dev.log(
        message,
        time: DateTime.now(),
        level: _getDevLogLevel(level),
        name: effectiveTag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static int _getDevLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 500;
      case LogLevel.info: return 800;
      case LogLevel.warning: return 900;
      case LogLevel.error: return 1000;
    }
  }

  /// Log API related activity
  static void api(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      AppLogger.error(message, tag: 'API', error: error);
    } else {
      AppLogger.info(message, tag: 'API');
    }
  }

  /// Log WebSocket related activity
  static void socket(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      AppLogger.error(message, tag: 'SOCKET', error: error);
    } else {
      AppLogger.info(message, tag: 'SOCKET');
    }
  }

  /// Log Geolocation related activity
  static void location(String message, {bool isError = false, dynamic error}) {
    if (isError) {
      AppLogger.error(message, tag: 'LOCATION', error: error);
    } else {
      AppLogger.info(message, tag: 'LOCATION');
    }
  }
}

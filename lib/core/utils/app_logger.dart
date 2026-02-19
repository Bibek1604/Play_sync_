import 'package:flutter/foundation.dart';

/// Lightweight app logger that mutes output in release mode.
///
/// Usage:
/// ```dart
/// AppLogger.i('User logged in');
/// AppLogger.e('API error', error, stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  static const _reset = '\x1B[0m';
  static const _cyan = '\x1B[36m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';

  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_cyan[INFO]${tag != null ? "[$tag]" : ""} $message$_reset');
    }
  }

  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint('$_green[DEBUG]${tag != null ? "[$tag]" : ""} $message$_reset');
    }
  }

  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      debugPrint(
          '$_yellow[WARN]${tag != null ? "[$tag]" : ""} $message$_reset');
    }
  }

  static void e(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      debugPrint('$_red[ERROR] $message$_reset');
      if (error != null) debugPrint('$_red  ↳ $error$_reset');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void socket(String event, {Object? payload}) {
    if (kDebugMode) {
      debugPrint('$_cyan[SOCKET] $event${payload != null ? " → $payload" : ""}$_reset');
    }
  }
}

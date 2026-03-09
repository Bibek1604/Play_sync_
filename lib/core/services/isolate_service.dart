import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:play_sync_new/core/services/app_logger.dart';

/// Utility to run heavy operations in a separate isolate.
/// Use this for complex data processing, heavy Hive queries, 
/// or any operation that blocks the UI thread for more than 16ms.
class IsolateService {
  IsolateService._();

  /// Runs a function in a separate isolate and returns the result.
/// This uses [compute] which is simple and effective for most tasks.
  /// For more complex long-lived background tasks, consider [Isolate.run].
  static Future<T> run<Q, T>(ComputeCallback<Q, T> callback, Q message, {String? debugName}) async {
    final name = debugName ?? 'Isolated Task';
    AppLogger.debug('Starting isolated task: $name', tag: 'ISOLATE');
    
    final stopwatch = Stopwatch()..start();
    try {
      final result = await compute(callback, message);
      stopwatch.stop();
      AppLogger.debug(
        'Isolated task "$name" completed in ${stopwatch.elapsedMilliseconds}ms', 
        tag: 'ISOLATE'
      );
      return result;
    } catch (e, stack) {
      stopwatch.stop();
      AppLogger.error(
        'Isolated task "$name" failed after ${stopwatch.elapsedMilliseconds}ms', 
        tag: 'ISOLATE', 
        error: e, 
        stackTrace: stack
      );
      rethrow;
    }
  }
}

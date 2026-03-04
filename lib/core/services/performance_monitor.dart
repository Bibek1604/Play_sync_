import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:play_sync_new/core/services/app_logger.dart';

/// Monitoring utility for app performance and frame drops.
class PerformanceMonitor {
  PerformanceMonitor._();

  static bool _isMonitoring = false;

  /// Start monitoring for frame drops and UI thread jank.
  static void startFrameMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    AppLogger.info('Starting Performance Monitoring (Frame Drops)', tag: 'PERF');

    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final timing in timings) {
        // Total time should ideally be under 16.6ms for 60fps
        final totalTime = timing.totalSpan.inMilliseconds;
        final buildTime = timing.buildDuration.inMilliseconds;
        final rasterTime = timing.rasterDuration.inMilliseconds;

        if (totalTime > 20) {
          AppLogger.warning(
            'High frame time detected: ${totalTime}ms (Build: ${buildTime}ms, Raster: ${rasterTime}ms)',
            tag: 'PERF',
          );
        }
      }
    });
  }

  /// Utility to measure how long a specific task takes to execute.
  static Future<T> traceTask<T>(String name, Future<T> Function() task) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await task();
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 100) {
        AppLogger.warning(
          'Heavy task detected: "$name" took ${stopwatch.elapsedMilliseconds}ms',
          tag: 'PERF',
        );
      } else {
        AppLogger.debug(
          'Task "$name" took ${stopwatch.elapsedMilliseconds}ms',
          tag: 'PERF',
        );
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Task "$name" failed after ${stopwatch.elapsedMilliseconds}ms', tag: 'PERF');
      rethrow;
    }
  }
}

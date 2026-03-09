import 'package:flutter/foundation.dart';
import 'package:play_sync_new/core/database/hive_init.dart';
import 'package:play_sync_new/core/services/app_logger.dart';
import 'package:play_sync_new/core/services/connectivity_service.dart';
import 'package:play_sync_new/core/services/payment_service.dart';
// import 'package:play_sync_new/core/services/location_service.dart'; // REMOVED: Geolocator causing issues
import 'package:play_sync_new/core/services/performance_monitor.dart';
import 'package:play_sync_new/app/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper class to coordinate all async initializations during app startup.
class ServiceInitializer {
  ServiceInitializer._();

  /// Initialize all required services.
/// This is called after the first frame renders to avoid blocking the UI.
  static Future<void> initialize(WidgetRef ref) async {
    final stopwatch = Stopwatch()..start();
    
    // Start monitoring frames for performance drops
    PerformanceMonitor.startFrameMonitoring();
    
    debugPrint('[INIT] 🔧 Starting service initialization...');
    AppLogger.info('Starting service initialization...', tag: 'INIT');

    try {
      // 1. Initialize Hive (Crucial for auth/settings)
      debugPrint('[INIT] 📦 Initializing Hive database...');
      await HiveInit.initialize();
      debugPrint('[INIT] ✓ Hive initialized successfully');
      AppLogger.info('Hive initialized');

      // 1.5. Initialize Theme Mode (Depends on Hive)
      debugPrint('[INIT] 🎨 Initializing Theme mode...');
      await ref.read(themeModeProvider.notifier).init();
      debugPrint('[INIT] ✓ Theme mode initialized');

      // 2. Initialize Payment Service
      debugPrint('[INIT] 💳 Initializing Payment Service...');
      await PaymentService.initialize();
      debugPrint('[INIT] ✓ Payment Service initialized');

      // 3. Connectivity Check (Optional, but good to know at startup)
      debugPrint('[INIT] 🌐 Checking backend connectivity...');
      final connectivity = ConnectivityService();
      final isOnline = await connectivity.isBackendAvailable();
      debugPrint('[INIT] ${isOnline ? "✓" : "✗"} Backend: ${isOnline ? "ONLINE" : "OFFLINE"}');
      AppLogger.info('Backend availability: ${isOnline ? "ONLINE" : "OFFLINE"}');

      // 3. Location Service - REMOVED TEMPORARILY
      // TODO: Re-enable when Geolocator multiple Flutter engine issue is resolved
      // LocationService.hasPermission().then((hasPerm) {
      //   AppLogger.info('Location permission: ${hasPerm ? "GRANTED" : "NOT GRANTED"}');
      // });
      debugPrint('[INIT] ⚠️  Location service disabled (Geolocator removed)');

      stopwatch.stop();
      debugPrint('[INIT] ✓ All services initialized in ${stopwatch.elapsedMilliseconds}ms');
      AppLogger.info(
        'Service initialization completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'INIT',
      );
    } catch (e, stack) {
      debugPrint('[INIT] ✗ CRITICAL FAILURE: $e');
      debugPrint('[INIT] Stack trace: $stack');
      AppLogger.error(
        'Critical failure during service initialization',
        tag: 'INIT',
        error: e,
        stackTrace: stack,
      );
      // App can still continue with limited functionality
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:play_sync_new/core/services/service_initializer.dart';
import 'app/app.dart';

/// Application Entry Point
///
/// Renders UI immediately, then initializes services asynchronously.
/// This prevents blocking the UI thread and allows the app to open quickly.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[MAIN] ========================================');
  debugPrint('[MAIN] PlaySync App Starting...');
  debugPrint('[MAIN] ========================================');

  // Run the app immediately - UI will render while services initialize
  runApp(const ProviderScope(child: PlaySyncApp()));

  // Initialize services after first frame is rendered
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    debugPrint('[MAIN] First frame rendered, starting service initialization...');
    try {
      await ServiceInitializer.initialize();
      debugPrint('[MAIN] ✓ All services initialized successfully');
    } catch (e, stack) {
      debugPrint('[MAIN] ✗ Service initialization failed: $e');
      debugPrint('[MAIN] Stack trace: $stack');
    }
  });
}

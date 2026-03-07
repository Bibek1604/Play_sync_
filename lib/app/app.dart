import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_router.dart';
import 'theme/theme_provider.dart';
import 'theme/dynamic_theme_service.dart';
import '../core/providers/socket_provider.dart';
import '../core/services/service_initializer.dart';

/// PlaySync Application Root Widget
///
/// Main application widget with theme and routing configuration.
class PlaySyncApp extends ConsumerStatefulWidget {
  const PlaySyncApp({super.key});

  @override
  ConsumerState<PlaySyncApp> createState() => _PlaySyncAppState();
}

class _PlaySyncAppState extends ConsumerState<PlaySyncApp> {
  @override
  void initState() {
    super.initState();
    // Initialize services after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint(
        '[MAIN] First frame rendered in PlaySyncApp, starting initialization...',
      );
      try {
        await ServiceInitializer.initialize(ref);
        debugPrint('[MAIN] ✓ All services initialized successfully');
      } catch (e, stack) {
        debugPrint('[MAIN] ✗ Service initialization failed: $e');
        debugPrint('[MAIN] Stack trace: $stack');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch resolved theme mode from persisted user/system preference
    final themeMode = ref.watch(dynamicThemeModeProvider);

    // Initialize socket connection (auto-connects when authenticated)
    ref.watch(socketProvider);

    return MaterialApp(
      title: 'PlaySync',
      debugShowCheckedModeBanner: false,

      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Routing Configuration
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

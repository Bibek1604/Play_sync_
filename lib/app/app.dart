import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_router.dart';
import 'theme/theme_provider.dart';
import '../core/providers/socket_provider.dart';

/// PlaySync Application Root Widget
/// 
/// Main application widget with theme and routing configuration.
class PlaySyncApp extends ConsumerWidget {
  const PlaySyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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

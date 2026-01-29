import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/widgets/auth_guard.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/theme_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Application Router
/// 
/// Handles all navigation and route generation for the app.
/// Uses named routes for easy navigation management.
class AppRouter {
  // Prevent instantiation
  AppRouter._();

  /// Initial route when app starts
  static const String initialRoute = AppRoutes.splash;

  /// Generate routes based on route settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.signup:
        return _buildRoute(const SignupPage(), settings);

      // Protected Routes (require authentication)
      case AppRoutes.dashboard:
        return _buildRoute(
          const AuthGuard(child: DashboardPage()),
          settings,
        );

      case AppRoutes.settings:
        return _buildRoute(
          const AuthGuard(child: SettingsPage()),
          settings,
        );

      case AppRoutes.profile:
        return _buildRoute(
          const AuthGuard(child: ProfilePage()),
          settings,
        );

      case AppRoutes.theme:
        return _buildRoute(
          const AuthGuard(child: ThemePage()),
          settings,
        );

      // Default - Unknown route
      default:
        return _buildRoute(
          const _UnknownRoutePage(),
          settings,
        );
    }
  }

  /// Build a MaterialPageRoute with consistent settings
  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// Get all named routes (for MaterialApp.routes)
  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.signup: (_) => const SignupPage(),
        AppRoutes.dashboard: (_) => const AuthGuard(child: DashboardPage()),
        AppRoutes.settings: (_) => const AuthGuard(child: SettingsPage()),
        AppRoutes.profile: (_) => const AuthGuard(child: ProfilePage()),
        AppRoutes.theme: (_) => const AuthGuard(child: ThemePage()),
      };
}

/// Fallback page for unknown routes
class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page does not exist.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.dashboard,
                  (route) => false,
                );
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

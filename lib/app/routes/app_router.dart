import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/widgets/auth_guard.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/theme_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/game/presentation/pages/available_games_page.dart';
import '../../features/game/presentation/pages/online_games_page.dart';
import '../../features/game/presentation/pages/offline_games_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/game/presentation/pages/game_chat_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/scorecard/scorecard.dart';
import '../../features/history/presentation/pages/game_history_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../core/widgets/app_shell.dart';

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
      // ── Auth ─────────────────────────────────────────────────────────────
      case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.signup:
        return _buildRoute(const SignupPage(), settings);

      // ── App Shell (bottom-nav host) ───────────────────────────────────────
      case AppRoutes.dashboard:
        return _buildRoute(
          const AuthGuard(child: AppShell()),
          settings,
        );

      // ── Stand-alone protected pages ───────────────────────────────────────
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

      // ── Game routes ───────────────────────────────────────────────────────
      case AppRoutes.game:
        return _buildRoute(
          const AuthGuard(child: GamePage()),
          settings,
        );

      case AppRoutes.availableGames:
        return _buildRoute(
          const AuthGuard(child: AvailableGamesPage()),
          settings,
        );

      case AppRoutes.onlineGames:
        return _buildRoute(
          const AuthGuard(child: OnlineGamesPage()),
          settings,
        );

      case AppRoutes.offlineGames:
        return _buildRoute(
          const AuthGuard(child: OfflineGamesPage()),
          settings,
        );

      // ── Game Chat (per-game room) ─────────────────────────────────────
      case AppRoutes.gameChat:
        final args = settings.arguments as Map<String, String>;
        return _buildRoute(
          AuthGuard(
            child: GameChatPage(
              gameId: args['gameId']!,
              gameTitle: args['gameTitle']!,
            ),
          ),
          settings,
        );

      // ── Scorecard ─────────────────────────────────────────────────────────
      case AppRoutes.scorecard:
        return _buildRoute(
          const AuthGuard(child: ScorecardPage()),
          settings,
        );

      // ── Social / Chat ────────────────────────────────────────────────────
      case AppRoutes.chat:
        return _buildRoute(
          const AuthGuard(child: ChatPage()),
          settings,
        );

      case AppRoutes.rankings:
        return _buildRoute(
          const AuthGuard(child: LeaderboardPage()),
          settings,
        );

      case AppRoutes.gameHistory:
        return _buildRoute(
          const AuthGuard(child: GameHistoryPage()),
          settings,
        );

      case AppRoutes.notifications:
        return _buildRoute(
          const AuthGuard(child: NotificationsPage()),
          settings,
        );

      // ── Fallback ──────────────────────────────────────────────────────────
      default:
        return _buildRoute(
          const _UnknownRoutePage(),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}

/// Fallback page for unknown routes
class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('The requested page does not exist.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.dashboard, (r) => false),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

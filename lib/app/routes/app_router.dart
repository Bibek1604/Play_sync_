import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/widgets/auth_guard.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/theme_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/location/presentation/pages/location_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/game/presentation/pages/game_detail_page.dart';
import '../../features/game/presentation/pages/available_games_page.dart';
import '../../features/game/presentation/pages/online_games_page.dart';
import '../../features/game/presentation/pages/offline_games_page.dart';
import '../../features/game/presentation/pages/ended_games_page.dart';
import '../../features/game/domain/entities/game_entity.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/game/presentation/pages/game_chat_rest_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/scorecard/scorecard.dart';
import '../../features/history/presentation/pages/game_history_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../core/widgets/app_shell.dart';

/// Application Router
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
case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.signup:
        return _buildRoute(const SignupPage(), settings);

      case AppRoutes.forgotPassword:
        return _buildRoute(const ForgotPasswordPage(), settings);

      case AppRoutes.verifyOtp:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          VerifyOtpPage(email: args?['email'] as String?),
          settings,
        );

      case AppRoutes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ResetPasswordPage(
            email: args?['email'] as String?,
            otp: args?['otp'] as String?,
          ),
          settings,
        );
case AppRoutes.dashboard:
        return _buildRoute(const AuthGuard(child: AppShell()), settings);
case AppRoutes.settings:
        return _buildRoute(const AuthGuard(child: SettingsPage()), settings);

      case AppRoutes.profile:
        return _buildRoute(const AuthGuard(child: ProfilePage()), settings);

      case AppRoutes.theme:
        return _buildRoute(const AuthGuard(child: ThemePage()), settings);

      case AppRoutes.location:
        return _buildRoute(const AuthGuard(child: LocationPage()), settings);
case AppRoutes.game:
        return _buildRoute(const AuthGuard(child: GamePage()), settings);

      case AppRoutes.availableGames:
        return _buildRoute(
          const AuthGuard(child: AvailableGamesPage()),
          settings,
        );

      case AppRoutes.onlineGames:
        return _buildRoute(const AuthGuard(child: OnlineGamesPage()), settings);

      case AppRoutes.offlineGames:
        return _buildRoute(
          const AuthGuard(child: OfflineGamesPage()),
          settings,
        );

      case AppRoutes.endedGames:
        return _buildRoute(const AuthGuard(child: EndedGamesPage()), settings);
case AppRoutes.gameDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final gameId = args['gameId'] as String? ?? '';
        return _buildRoute(
          AuthGuard(child: GameDetailPage(gameId: gameId)),
          settings,
        );
case AppRoutes.gameChat:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final game = args['game'] as GameEntity?;
        if (game == null) {
          // Fallback: Game object required
          // Users should pass full GameEntity via MaterialPageRoute
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text(
                  'Error: Game not found. Please navigate from game details.',
                ),
              ),
            ),
          );
        }
        return _buildRoute(
          AuthGuard(child: GameChatRestPage(game: game)),
          settings,
        );
case AppRoutes.scorecard:
        return _buildRoute(const AuthGuard(child: ScorecardPage()), settings);
case AppRoutes.chat:
        return _buildRoute(const AuthGuard(child: ChatPage()), settings);

      case AppRoutes.rankings:
        return _buildRoute(const AuthGuard(child: LeaderboardPage()), settings);

      case AppRoutes.gameHistory:
        return _buildRoute(const AuthGuard(child: GameHistoryPage()), settings);

      case AppRoutes.notifications:
        return _buildRoute(
          const AuthGuard(child: NotificationsPage()),
          settings,
        );
/*
      case AppRoutes.tournaments:
        return _buildRoute(
          const AuthGuard(child: TournamentListPage()),
          settings,
        );

      case AppRoutes.tournamentDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final tournament = args['tournament'] as TournamentEntity?;
        
        if (tournament == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Error: Tournament details not found.'),
              ),
            ),
          );
        }

        return _buildRoute(
          AuthGuard(child: TournamentDetailPage(tournament: tournament)),
          settings,
        );

      case AppRoutes.tournamentCreate:
        final args = settings.arguments as Map<String, dynamic>?;
        final existing = args?['tournament'] as TournamentEntity?;
        return _buildRoute(
          AuthGuard(child: CreateTournamentPage(existingTournament: existing)),
          settings,
        );

      case AppRoutes.tournamentChat:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _buildRoute(
          AuthGuard(
            child: TournamentChatPage(
              tournamentId: args['tournamentId'] as String? ?? '',
              tournamentName: args['tournamentName'] as String? ?? 'Chat',
            ),
          ),
          settings,
        );

      case AppRoutes.tournamentPayments:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _buildRoute(
          AuthGuard(
            child: TournamentPaymentsPage(
              tournamentId: args['tournamentId'] as String? ?? '',
            ),
          ),
          settings,
        );

      case AppRoutes.esewaPayment:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return _buildRoute(
          AuthGuard(
            child: EsewaPaymentPage(
              paymentUrl: args['paymentUrl'] as String? ?? '',
              params: args['params'] as Map<String, dynamic>? ?? {},
              tournamentId: args['tournamentId'] as String? ?? '',
            ),
          ),
          settings,
        );

      case AppRoutes.tournamentPayment:
        final tournament = settings.arguments as TournamentEntity?;
        if (tournament == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Error: Tournament not found.'),
              ),
            ),
          );
        }
        return _buildRoute(
          AuthGuard(child: TournamentPaymentScreen(tournament: tournament)),
          settings,
        );

      case AppRoutes.paymentSuccess:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final tournament = args['tournament'] as TournamentEntity?;
        final payment = args['payment'] as TournamentPaymentEntity?;
        if (tournament == null || payment == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Error: Payment details not found.'),
              ),
            ),
          );
        }
        return _buildRoute(
          AuthGuard(
            child: PaymentSuccessScreen(
              tournament: tournament,
              payment: payment,
            ),
          ),
          settings,
        );

      case AppRoutes.paymentFailed:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final tournament = args['tournament'] as TournamentEntity?;
        final error = args['error'] as String? ?? 'Payment failed';
        if (tournament == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Error: Tournament not found.'),
              ),
            ),
          );
        }
        return _buildRoute(
          AuthGuard(
            child: PaymentFailedScreen(
              tournament: tournament,
              error: error,
            ),
          ),
          settings,
        );
      */
default:
        return _buildRoute(const _UnknownRoutePage(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
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
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page does not exist.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (r) => false,
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

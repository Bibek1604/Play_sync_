/// Application route names
/// 
/// Centralized route definitions for navigation throughout the app.
/// All route paths are defined as static constants for type-safety.
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  // Main App Shell (bottom nav host)
  static const String dashboard = '/dashboard';

  // Profile & Account
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String theme = '/theme';

  // Game Routes
  static const String game = '/game';
  static const String availableGames = '/available-games';
  static const String onlineGames = '/online-games';
  static const String offlineGames = '/offline-games';

  // Chat
  static const String chat = '/chat';

  // Game Chat (per-game room, pass Map<String,String> {gameId, gameTitle} as arguments)
  static const String gameChat = '/game-chat';

  // Scorecard
  static const String scorecard = '/scorecard';

  // Social
  static const String rankings = '/rankings';
  static const String gameHistory = '/game-history';
  static const String notifications = '/notifications';

  // Legacy / future
  static const String discover = '/discover';
  static const String friends = '/friends';
  static const String messages = '/messages';
  static const String events = '/events';
}

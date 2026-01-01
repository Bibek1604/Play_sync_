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

  // Main App Routes
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String theme = '/theme';

  // Feature Routes (future)
  static const String profile = '/profile';
  static const String discover = '/discover';
  static const String friends = '/friends';
  static const String messages = '/messages';
  static const String events = '/events';
  static const String rankings = '/rankings';
}

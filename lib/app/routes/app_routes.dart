class AppRoutes {
  AppRoutes._();

  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  // Main App Shell (bottom nav host)
  static const String dashboard = '/dashboard';

  // Profile & Account
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String theme = '/theme';
  static const String location = '/location';

  // Game Routes
  static const String game = '/game';
  static const String gameDetail = '/game-detail';
  static const String availableGames = '/available-games';
  static const String onlineGames = '/online-games';
  static const String offlineGames = '/offline-games';
  static const String endedGames = '/ended-games';

  // Chat
  static const String chat = '/chat';

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

  // Tournament Routes
  static const String tournaments = '/tournaments';
  static const String tournamentDetail = '/tournament-detail';
  static const String tournamentCreate = '/tournament-create';
  static const String tournamentChat = '/tournament-chat';
  static const String tournamentPayments = '/tournament-payments';
  static const String tournamentPayment = '/tournament-payment';
  static const String esewaPayment = '/esewa-payment';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailed = '/payment-failed';
}

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// API Endpoints for the application
class ApiEndpoints {
  ApiEndpoints._();

  // ========== BASE URL & TIMEOUTS ==========

  /// Override via: flutter run --dart-define=DEV_BACKEND_URL=http://192.168.x.x:5000/api/v1
  static const String _customBackendUrl = String.fromEnvironment('DEV_BACKEND_URL', defaultValue: '');

  static String get baseUrl {
    // If a custom URL is provided at build time (for physical device dev), use it
    if (_customBackendUrl.isNotEmpty) {
      return _customBackendUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    
    // For Android physical device, use the development machine's IP
    // For emulator, use --dart-define=DEV_BACKEND_URL=http://10.0.2.2:5000/api/v1
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.18.57:5000/api/v1';
      }
    } catch (_) {
      // Platform check may fail on some web environments if not handled by kIsWeb
    }
    
    return 'http://localhost:5000/api/v1';
  }

  // ========== IMAGE BASE URL ==========
  static String get imageBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.18.57:5000';
      }
    } catch (_) {
      // Platform check may fail
    }
    
    return 'http://localhost:5000';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ========== AUTH ENDPOINTS ==========
  static const String registerUser = '/auth/register/user';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String getCurrentUser = '/auth/me';

  // ========== PROFILE ENDPOINTS ==========
  static const String getProfile = '/profile';
  static const String updateProfile = '/profile';
  static String getProfileById(String userId) => '/profile/$userId';
  static const String uploadProfilePicture = '/profile/avatar';
  static const String uploadCoverPicture = '/profile/cover';
  static const String uploadGalleryPictures = '/profile/pictures';
  static const String deleteProfilePicture = '/profile/avatar';

  // ========== USER ENDPOINTS ==========
  // static const String getUsers = '/users';
  // static const String getUserById = '/users/:id';
  // static const String updateUser = '/users/:id';
  // static const String deleteUser = '/users/:id';

  // ========== PRODUCT ENDPOINTS ==========
  // static const String getProducts = '/products';
  // static const String getProductById = '/products/:id';
  // static const String createProduct = '/products';
  // static const String updateProduct = '/products/:id';
  // static const String deleteProduct = '/products/:id';

  // ========== ADMIN CODE ==========
  static const String adminCode = 'your-super-secret-key-2025';

  // ========== GAME ENDPOINTS ==========
  static const String createGame = '/games';
  static const String getGames = '/games';
  static const String getMyCreatedGames = '/games/my/created';
  static const String getMyJoinedGames = '/games/my/joined';
  static const String getPopularTags = '/games/tags/popular';
  static String getGameById(String id) => '/games/$id?details=true';
  static String joinGame(String id) => '/games/$id/join';
  static String leaveGame(String id) => '/games/$id/leave';
  static String canJoinGame(String id) => '/games/$id/can-join';
  static String updateGame(String id) => '/games/$id';
  static String deleteGame(String id) => '/games/$id';
  static String cancelGame(String id) => '/games/$id/cancel';
  static String completeGame(String id) => '/games/$id/complete';

  // ========== INVITE LINK ENDPOINTS ==========
  static String generateInviteLink(String id) => '/games/$id/invite';
  static String getInviteDetails(String code) => '/games/invite/$code';
  static String joinViaInvite(String code) => '/games/invite/$code/join';

  // ========== GAME INVITATION ENDPOINTS ==========
  static String sendGameInvitation(String gameId) => '/games/$gameId/invite';
  static const String getMyInvitations = '/games/me/invitations';
  static String respondToInvitation(String invitationId) =>
      '/games/invitations/$invitationId/respond';

  // ========== GAME CHAT ENDPOINTS ==========
  static String sendChatMessage(String gameId) => '/games/$gameId/chat';
  static String getChatMessages(String gameId) => '/games/$gameId/chat';
  static const String getJoinedChatPreview = '/games/my/joined/chat-preview';

  // ========== HISTORY ENDPOINTS ==========
  static const String getHistory = '/history';
  static const String getHistoryStats = '/history/stats';
  static const String getHistoryCount = '/history/count';

  // ========== SCORECARD ENDPOINTS ==========
  static const String getMyScorecard = '/users/me/scorecard';

  // ========== LEADERBOARD ENDPOINTS ==========
  static const String getLeaderboard = '/leaderboard';
  static const String getLeaderboardStats = '/leaderboard/stats';

  // ========== NOTIFICATIONS ENDPOINTS ==========
  static const String getNotifications = '/notifications';
  static const String getUnreadNotificationsCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // ========== TOURNAMENT ENDPOINTS ==========
  static const String getTournaments = '/tournaments';
  static const String createTournament = '/tournaments';
  static const String getMyTournaments = '/tournaments/mine/list';
  static String getTournamentById(String id) => '/tournaments/$id';
  static String updateTournament(String id) => '/tournaments/$id';
  static String deleteTournament(String id) => '/tournaments/$id';

  // ========== TOURNAMENT PAYMENT (eSewa) ==========
  static const String initiatePayment = '/payments/initiate';
  static const String verifyPayment = '/payments/verify';
  static String getPaymentStatus(String id) => '/tournaments/$id/payment/status';
  static String checkChatAccess(String id) => '/tournaments/$id/chat/access';
  static const String getDashboardTransactions = '/payments/admin/transactions';
  static String getTournamentPayments(String id) => '/tournaments/$id/payments';

  // ========== ADMIN ENDPOINTS ==========
  static const String getAdminStats = '/admin/stats';
  static const String getAdminUsers = '/admin/users';
  static String getAdminUserById(String id) => '/admin/users/$id';
  static const String getAdminGames = '/admin/games';
  static const String getAdminOnlineGames = '/admin/games/online';
  static const String getAdminOfflineGames = '/admin/games/offline';
  static String getAdminGameById(String id) => '/admin/games/$id';

  // ========== PASSWORD ENDPOINTS ==========
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/profile/change-password';
  static const String getAllUsers = '/auth/users';
}

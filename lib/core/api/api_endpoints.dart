import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// API Endpoints for the application
class ApiEndpoints {
  ApiEndpoints._();

  // ========== BASE URL & TIMEOUTS ==========
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    
    // For Android Emulator, use 10.0.2.2 to access host's localhost
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
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
        return 'http://10.0.2.2:5000';
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
  static const String uploadProfilePicture = '/profile/avatar';
  static const String uploadCoverPicture = '/profile/cover';
  static const String uploadGalleryPictures = '/profile/pictures';
  static const String deleteProfilePicture = '/profile/avatar';

  // ========== GAME ENDPOINTS ==========
  static const String createGame = '/games';
  static const String getAllGames = '/games';
  static const String getGameById = '/games/:id';
  static const String getMyCreatedGames = '/games/my/created';
  static const String getMyJoinedGames = '/games/my/joined';
  static const String joinGame = '/games/:id/join';
  static const String leaveGame = '/games/:id/leave';
  static const String canJoinGame = '/games/:id/can-join';
  static const String updateGame = '/games/:id';
  static const String deleteGame = '/games/:id';
  static const String cancelGame = '/games/:id/cancel';
  static const String completeGame = '/games/:id/complete';
  static const String getPopularTags = '/games/tags/popular';

  // ========== GAME CHAT ENDPOINTS ==========
  static const String sendChatMessage = '/games/:gameId/chat';
  static const String getChatMessages = '/games/:gameId/chat';
  static const String getJoinedChatPreview = '/games/my/joined/chat-preview';

  // ========== USER ENDPOINTS ==========
  // Note: user routes are mounted at /profile in the backend (userRoutes → /api/v1/profile)
  static const String getGameContacts = '/profile/game-contacts';

  // ========== HISTORY ENDPOINTS ==========
  static const String historyList = '/history';
  static const String historyStats = '/history/stats';
  static const String historyCount = '/history/count';

  // ========== LEADERBOARD ENDPOINTS ==========
  static const String leaderboardList = '/leaderboard';
  static const String leaderboardStats = '/leaderboard/stats';

  // ========== NOTIFICATION ENDPOINTS ==========
  static const String notificationsList = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsMarkRead = '/notifications/:id/read';
  static const String notificationsReadAll = '/notifications/read-all';

  // ========== SCORECARD ENDPOINTS ==========
  static const String scorecardGet = '/scorecard';
  static const String scorecardTrend = '/scorecard/trend';

  // ========== SOCKET EVENTS ==========
  // Outgoing (client → server)
  static const String socketJoinGame = 'game:join';
  static const String socketLeaveGame = 'game:leave';
  static const String socketSubscribeGame = 'game:subscribe';
  static const String socketChatSend = 'chat:send';

  // Incoming (server → client)
  static const String socketGameUpdate = 'game:updated';
  static const String socketPlayerJoined = 'game:player_joined';
  static const String socketPlayerLeft = 'game:player_left';
  // chat:message is used for both user messages and system messages
  static const String socketChatMessage = 'chat:message';
  // Backend emits 'game:status:changed' via GameEventsEmitter
  static const String socketGameStatusChanged = 'game:status:changed';
  static const String socketError = 'error';

  // ========== NOTIFICATION SOCKET EVENTS ==========
  // Incoming (server → client), user rooms: user:{userId}
  static const String socketNotification = 'notification';
  static const String socketNotificationUnreadCount = 'notification:unread-count';
  static const String socketNotificationRead = 'notification:read';
  static const String socketNotificationAllRead = 'notification:all-read';

  // ========== UTILITY METHODS ==========
  
  /// Replace path parameters (e.g., :id) with actual values
  static String replacePath(String path, Map<String, dynamic> params) {
    var result = path;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value.toString());
    });
    return result;
  }

  // ========== ADMIN CODE ==========
  static const String adminCode = 'your-super-secret-key-2025';
}

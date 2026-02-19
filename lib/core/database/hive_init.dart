import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/features/game/data/models/game_dto.dart';
import 'package:play_sync_new/features/game/data/models/game_dto_adapter.dart';
import 'package:play_sync_new/features/history/data/models/game_history_dto.dart';
import 'package:play_sync_new/features/history/data/models/game_history_dto_adapter.dart';
import 'package:play_sync_new/features/leaderboard/data/models/leaderboard_entry_dto_adapter.dart';
import 'package:play_sync_new/features/notifications/data/models/notification_dto_adapter.dart';
import 'package:play_sync_new/features/profile/data/models/profile_response_model.dart';
import 'package:play_sync_new/features/profile/data/models/profile_response_model_adapter.dart';
import 'package:play_sync_new/features/scorecard/data/models/scorecard_dto_adapter.dart';
import 'package:play_sync_new/features/game/data/models/chat_message_dto_adapter.dart';

/// Hive Database Initialization
/// 
/// Handles all Hive setup including adapter registration and box initialization
class HiveInit {
  /// Initialize Hive with all type adapters and boxes
  static Future<void> initialize() async {
    // Initialize Hive with Flutter
    await Hive.initFlutter();

    // Register Type Adapters
    _registerAdapters();

    // Open All Boxes
    await _openBoxes();
  }

  /// Register all Hive type adapters
  static void _registerAdapters() {
    // Check if adapter is already registered before registering
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GameDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ParticipantDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(ActivityLogDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProfileResponseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(GameHistoryDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(UserDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(LeaderboardEntryDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(NotificationDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(BreakdownDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ScorecardDtoAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ChatMessageDtoAdapter());
    }
  }

  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    // Game feature boxes
    if (!Hive.isBoxOpen('games')) {
      await Hive.openBox<GameDto>('games');
    }
    if (!Hive.isBoxOpen('game_metadata')) {
      await Hive.openBox('game_metadata');
    }

    // Profile feature boxes
    if (!Hive.isBoxOpen('profile')) {
      await Hive.openBox<ProfileResponseModel>('profile');
    }
    if (!Hive.isBoxOpen('profile_metadata')) {
      await Hive.openBox('profile_metadata');
    }

    // History feature boxes
    if (!Hive.isBoxOpen('history')) {
      await Hive.openBox<GameHistoryDto>('history');
    }
    if (!Hive.isBoxOpen('history_metadata')) {
      await Hive.openBox('history_metadata');
    }

    // Leaderboard feature box
    if (!Hive.isBoxOpen('leaderboard_metadata')) {
      await Hive.openBox('leaderboard_metadata');
    }

    // Notifications feature box
    if (!Hive.isBoxOpen('notifications_metadata')) {
      await Hive.openBox('notifications_metadata');
    }

    // Chat feature box
    if (!Hive.isBoxOpen('chat_metadata')) {
      await Hive.openBox('chat_metadata');
    }

    // Scorecard feature box
    if (!Hive.isBoxOpen('scorecard_metadata')) {
      await Hive.openBox('scorecard_metadata');
    }

    // Auth feature box (if not already open)
    if (!Hive.isBoxOpen('auth')) {
      await Hive.openBox('auth');
    }
  }

  /// Close all Hive boxes (call on app dispose/exit)
  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }

  /// Clear all cached data (useful for logout)
  static Future<void> clearAllCache() async {
    await Hive.box<GameDto>('games').clear();
    await Hive.box('game_metadata').clear();
    await Hive.box<ProfileResponseModel>('profile').clear();
    await Hive.box('profile_metadata').clear();
    await Hive.box<GameHistoryDto>('history').clear();
    await Hive.box('history_metadata').clear();
    await Hive.box('leaderboard_metadata').clear();
    await Hive.box('notifications_metadata').clear();
    await Hive.box('scorecard_metadata').clear();
  }

  /// Clear specific feature cache
  static Future<void> clearFeatureCache(String feature) async {
    switch (feature) {
      case 'game':
        await Hive.box<GameDto>('games').clear();
        await Hive.box('game_metadata').clear();
        break;
      case 'profile':
        await Hive.box<ProfileResponseModel>('profile').clear();
        await Hive.box('profile_metadata').clear();
        break;
      case 'history':
        await Hive.box<GameHistoryDto>('history').clear();
        await Hive.box('history_metadata').clear();
        break;
      case 'leaderboard':
        await Hive.box('leaderboard_metadata').clear();
        break;
      case 'notifications':
        await Hive.box('notifications_metadata').clear();
        break;
      case 'scorecard':
        await Hive.box('scorecard_metadata').clear();
        break;
    }
  }

  /// Get cache size for monitoring
  static Map<String, int> getCacheSizes() {
    return {
      'games': Hive.box<GameDto>('games').length,
      'profile': Hive.box<ProfileResponseModel>('profile').length,
      'history': Hive.box<GameHistoryDto>('history').length,
      'game_metadata': Hive.box('game_metadata').length,
      'profile_metadata': Hive.box('profile_metadata').length,
      'history_metadata': Hive.box('history_metadata').length,
      'leaderboard_metadata': Hive.box('leaderboard_metadata').length,
      'notifications_metadata': Hive.box('notifications_metadata').length,
      'scorecard_metadata': Hive.box('scorecard_metadata').length,
    };
  }
}

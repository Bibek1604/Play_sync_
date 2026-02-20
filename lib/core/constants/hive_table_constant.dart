/// Central location for all Hive-related constants
///
/// Type IDs must be unique within the range 0-223 for Hive adapters.
/// Follow sequential numbering when adding new types.
class HiveTableConstant {
  HiveTableConstant._();

  // Database name
  static const String dbName = 'play_sync_db';

  // ===== TYPE IDs =====
  // PlaySync domain models — globally unique, never reuse
  static const int gameDtoTypeId = 1;
  static const int profileTypeId = 3;
  static const int gameHistoryTypeId = 4;
  static const int userDtoTypeId = 5;
  static const int leaderboardEntryTypeId = 6;
  static const int notificationTypeId = 7;
  static const int breakdownDtoTypeId = 8;
  static const int scorecardTypeId = 9;
  static const int chatMessageTypeId = 10;
  static const int participantDtoTypeId = 11;
  static const int activityLogTypeId = 12;
  // Add new feature types starting at 13

  // ===== BOX NAMES =====
  // Authentication (dynamic, no Hive model adapter)
  static const String authBox = 'auth_box';

  // PlaySync feature boxes
  static const String gamesBox = 'games';
  static const String profileBox = 'profile';
  static const String historyBox = 'history';
  static const String leaderboardBox = 'leaderboard_metadata';
  static const String notificationsBox = 'notifications_metadata';
  static const String scorecardBox = 'scorecard';
  static const String chatBox = 'chat_cache';

  // Preferences / misc
  static const String preferencesBox = 'preferences';
  static const String cacheBox = 'cache';
  static const String syncBox = 'sync_queue';

  // Legacy box names kept for backward compatibility
  static const String userBoxName = 'userBox';
  static const String tokenBoxName = 'tokenBox';
  static const String registeredUsersBoxName = 'registered_users';
}

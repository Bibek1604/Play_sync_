import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_table_constant.dart';

/// Initialises Hive for the PlaySync app.
///
/// Call [HiveInit.initialize] once from `main()` before `runApp`.
/// All Hive type adapters are registered here; all named boxes are opened.
class HiveInit {
  HiveInit._();

  /// Initialise Hive — register adapters, open all required boxes.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
  }

  // ── Adapter Registration ──────────────────────────────────────────────────
  // When you add a new HiveType model, register its adapter here.
  // Use: if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(Adapter());
  static void _registerAdapters() {
    // Example (uncomment when adapters are generated via build_runner):
    // if (!Hive.isAdapterRegistered(HiveTableConstant.gameDtoTypeId)) {
    //   Hive.registerAdapter(GameDtoAdapter());
    // }
    // if (!Hive.isAdapterRegistered(HiveTableConstant.profileTypeId)) {
    //   Hive.registerAdapter(ProfileResponseModelAdapter());
    // }
    // if (!Hive.isAdapterRegistered(HiveTableConstant.gameHistoryTypeId)) {
    //   Hive.registerAdapter(GameHistoryDtoAdapter());
    // }
    // if (!Hive.isAdapterRegistered(HiveTableConstant.notificationTypeId)) {
    //   Hive.registerAdapter(NotificationDtoAdapter());
    // }
    // if (!Hive.isAdapterRegistered(HiveTableConstant.chatMessageTypeId)) {
    //   Hive.registerAdapter(ChatMessageDtoAdapter());
    // }
    debugPrint('[HiveInit] Adapters registered');
  }

  // ── Box Opening ───────────────────────────────────────────────────────────
  static Future<void> _openBoxes() async {
    final boxNames = [
      HiveTableConstant.authBox,
      HiveTableConstant.gamesBox,
      HiveTableConstant.profileBox,
      HiveTableConstant.historyBox,
      HiveTableConstant.leaderboardBox,
      HiveTableConstant.notificationsBox,
      HiveTableConstant.chatBox,
      HiveTableConstant.preferencesBox,
      // Legacy boxes for backward compatibility
      HiveTableConstant.userBoxName,
      HiveTableConstant.registeredUsersBoxName,
    ];

    for (final name in boxNames) {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox<dynamic>(name);
      }
    }
    debugPrint('[HiveInit] All boxes opened');
  }
}

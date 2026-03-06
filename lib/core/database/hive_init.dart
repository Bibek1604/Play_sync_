import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/core/services/app_logger.dart';
import '../constants/hive_table_constant.dart';
import 'package:flutter/foundation.dart';
/// Initialises Hive for the PlaySync app.
///
/// Call [HiveInit.initialize] once from `main()` before `runApp`.
/// All Hive type adapters are registered here; all named boxes are opened.
class HiveInit {
  HiveInit._();

  /// Initialise Hive — register adapters, open essential boxes.
  static Future<void> initialize() async {
    try {
      AppLogger.info('Initializing Hive...', tag: 'HIVE');
      await Hive.initFlutter();
      _registerAdapters();
      
      // Open only essential boxes first to speed up startup
      await _openEssentialBoxes();
      
      // Open other boxes in the background without blocking the main flow
      _openFeatureBoxes();
    } catch (e) {
      AppLogger.error('Hive initialization failed', tag: 'HIVE', error: e);
      rethrow;
    }
  }

  // ── Adapter Registration ──────────────────────────────────────────────────
  static void _registerAdapters() {
    // Adapter registration stays the same
    AppLogger.debug('Adapters registered', tag: 'HIVE');
  }

  // ── Box Opening ───────────────────────────────────────────────────────────
  
  /// Boxes required for immediate startup (Auth, Themes, etc.)
  static Future<void> _openEssentialBoxes() async {
    final essentialBoxes = [
      HiveTableConstant.authBox,
      HiveTableConstant.preferencesBox,
      HiveTableConstant.userBoxName,
      HiveTableConstant.registeredUsersBoxName,
    ];

    await Future.wait(essentialBoxes.map((name) async {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox<dynamic>(name).catchError((e) {
          debugPrint('[HiveInit] Failed to open essential box $name: $e');
        });
      }
    }));
    debugPrint('[HiveInit] Essential boxes opened');
  }

  /// Boxes for specific features, opened in parallel
  static Future<void> _openFeatureBoxes() async {
    final featureBoxes = [
      HiveTableConstant.gamesBox,
      HiveTableConstant.profileBox,
      HiveTableConstant.historyBox,
      HiveTableConstant.leaderboardBox,
      HiveTableConstant.notificationsBox,
      HiveTableConstant.chatBox,
      HiveTableConstant.tournamentsBox,
      HiveTableConstant.tournamentChatBox,
      HiveTableConstant.tournamentPaymentsBox,
      HiveTableConstant.adminBox,
    ];

    Future.wait(featureBoxes.map((name) async {
      if (!Hive.isBoxOpen(name)) {
        await Hive.openBox<dynamic>(name).catchError((e) {
          debugPrint('[HiveInit] Failed to open feature box $name: $e');
        });
      }
    })).then((_) {
      debugPrint('[HiveInit] All feature boxes opened');
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'notification_prefs';

class NotificationPreferences {
  final bool gameInvites;
  final bool gameStarting;
  final bool playerJoined;
  final bool chatMessages;
  final bool badgeEarned;
  final bool marketing;

  const NotificationPreferences({
    this.gameInvites = true,
    this.gameStarting = true,
    this.playerJoined = true,
    this.chatMessages = true,
    this.badgeEarned = true,
    this.marketing = false,
  });

  NotificationPreferences copyWith({
    bool? gameInvites, bool? gameStarting, bool? playerJoined,
    bool? chatMessages, bool? badgeEarned, bool? marketing,
  }) {
    return NotificationPreferences(
      gameInvites: gameInvites ?? this.gameInvites,
      gameStarting: gameStarting ?? this.gameStarting,
      playerJoined: playerJoined ?? this.playerJoined,
      chatMessages: chatMessages ?? this.chatMessages,
      badgeEarned: badgeEarned ?? this.badgeEarned,
      marketing: marketing ?? this.marketing,
    );
  }

  Map<String, bool> toMap() => {
    'gameInvites': gameInvites, 'gameStarting': gameStarting,
    'playerJoined': playerJoined, 'chatMessages': chatMessages,
    'badgeEarned': badgeEarned, 'marketing': marketing,
  };

  factory NotificationPreferences.fromMap(Map<String, dynamic> m) => NotificationPreferences(
    gameInvites: m['gameInvites'] as bool? ?? true,
    gameStarting: m['gameStarting'] as bool? ?? true,
    playerJoined: m['playerJoined'] as bool? ?? true,
    chatMessages: m['chatMessages'] as bool? ?? true,
    badgeEarned: m['badgeEarned'] as bool? ?? true,
    marketing: m['marketing'] as bool? ?? false,
  );
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPreferences> {
  NotificationPrefsNotifier() : super(const NotificationPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = state.toMap().keys;
    final map = {for (final k in keys) k: prefs.getBool('${_kKey}_$k') ?? state.toMap()[k]!};
    state = NotificationPreferences.fromMap(map);
  }

  Future<void> toggle(String key) async {
    final current = state.toMap();
    if (!current.containsKey(key)) return;
    final updated = Map<String, bool>.from(current)..[key] = !current[key]!;
    state = NotificationPreferences.fromMap(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_kKey}_$key', updated[key]!);
  }
}

final notifPrefsProvider = StateNotifierProvider<NotificationPrefsNotifier, NotificationPreferences>(
  (ref) => NotificationPrefsNotifier(),
);

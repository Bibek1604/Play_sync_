import 'package:flutter/material.dart';

/// Immutable value object holding all persisted app settings.
class AppSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final String languageCode;
  final Map<String, bool> notificationPrefs;
  final bool compactMode;
  final bool reducedMotion;

  const AppSettings({
    required this.themeMode,
    required this.accentColor,
    required this.languageCode,
    required this.notificationPrefs,
    this.compactMode = false,
    this.reducedMotion = false,
  });

  static AppSettings get defaults => AppSettings(
        themeMode: ThemeMode.system,
        accentColor: const Color(0xFF6C63FF),
        languageCode: 'en',
        notificationPrefs: {
          'push': true,
          'email': false,
          'game_invite': true,
          'friend_request': true,
          'achievement': true,
        },
      );

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    String? languageCode,
    Map<String, bool>? notificationPrefs,
    bool? compactMode,
    bool? reducedMotion,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      languageCode: languageCode ?? this.languageCode,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      compactMode: compactMode ?? this.compactMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          themeMode == other.themeMode &&
          accentColor == other.accentColor &&
          languageCode == other.languageCode &&
          compactMode == other.compactMode &&
          reducedMotion == other.reducedMotion;

  @override
  int get hashCode => Object.hash(themeMode, accentColor, languageCode, compactMode, reducedMotion);
}

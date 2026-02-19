import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/app_settings.dart';

/// Persists and restores all app settings via SharedPreferences.
class SettingsRepository {
  static const _keyTheme = 'settings.theme';
  static const _keyAccent = 'settings.accent';
  static const _keyLang = 'settings.language';
  static const _keyCompact = 'settings.compact';
  static const _keyReducedMotion = 'settings.reducedMotion';
  static const _notifPrefix = 'settings.notif.';

  final SharedPreferences _prefs;
  const SettingsRepository(this._prefs);

  /// Load all settings from persistence. Falls back to [AppSettings.defaults].
  Future<AppSettings> load() async {
    final themeIndex = _prefs.getInt(_keyTheme) ?? ThemeMode.system.index;
    final accentValue = _prefs.getInt(_keyAccent) ?? const Color(0xFF6C63FF).value;
    final lang = _prefs.getString(_keyLang) ?? 'en';
    final compact = _prefs.getBool(_keyCompact) ?? false;
    final reduced = _prefs.getBool(_keyReducedMotion) ?? false;

    final defaultNotifs = AppSettings.defaults.notificationPrefs;
    final notifPrefs = <String, bool>{};
    for (final key in defaultNotifs.keys) {
      notifPrefs[key] = _prefs.getBool('$_notifPrefix$key') ?? defaultNotifs[key]!;
    }

    return AppSettings(
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      accentColor: Color(accentValue),
      languageCode: lang,
      notificationPrefs: notifPrefs,
      compactMode: compact,
      reducedMotion: reduced,
    );
  }

  /// Persist any delta from the provided [settings] object.
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setInt(_keyTheme, settings.themeMode.index),
      _prefs.setInt(_keyAccent, settings.accentColor.value),
      _prefs.setString(_keyLang, settings.languageCode),
      _prefs.setBool(_keyCompact, settings.compactMode),
      _prefs.setBool(_keyReducedMotion, settings.reducedMotion),
      ...settings.notificationPrefs.entries.map(
        (e) => _prefs.setBool('$_notifPrefix${e.key}', e.value),
      ),
    ]);
  }

  /// Reset all settings to defaults.
  Future<void> reset() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('settings.')).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}

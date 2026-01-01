import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'light_theme.dart';
import 'dark_theme.dart';

/// Theme Mode Provider
/// 
/// Manages the current theme mode (light/dark/system) with persistence.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Theme Mode Notifier
/// 
/// Handles theme mode state with persistence to Hive.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  /// Load saved theme mode from Hive
  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedMode = box.get(_themeKey, defaultValue: 'system');
      state = _themeModeFromString(savedMode);
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  /// Set theme mode and persist
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_themeKey, _themeModeToString(mode));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Check if dark mode is active
  bool get isDarkMode => state == ThemeMode.dark;

  /// Check if light mode is active
  bool get isLightMode => state == ThemeMode.light;

  /// Check if system mode is active
  bool get isSystemMode => state == ThemeMode.system;

  /// Convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

/// App Theme Provider
/// 
/// Provides light and dark themes for the app.
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  /// Light theme
  static ThemeData get lightTheme => LightTheme.theme;

  /// Dark theme
  static ThemeData get darkTheme => DarkTheme.theme;
}

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hive_flutter/hive_flutter.dart";

import "light_theme.dart";
import "dark_theme.dart";

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _boxName = "settings";
  static const String _themeKey = "theme_mode";

  ThemeModeNotifier() : super(ThemeMode.system);

  Future<void> init() async {
    await _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedMode = box.get(_themeKey, defaultValue: "system");
      state = _themeModeFromString(savedMode);
    } catch (e) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_themeKey, _themeModeToString(mode));
    } catch (e) {
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
  bool get isLightMode => state == ThemeMode.light;
  bool get isSystemMode => state == ThemeMode.system;

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return "light";
      case ThemeMode.dark: return "dark";
      case ThemeMode.system: return "system";
    }
  }

  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case "light": return ThemeMode.light;
      case "dark": return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}

class AppTheme {
  AppTheme._();
  static ThemeData get lightTheme => LightTheme.theme;
  static ThemeData get darkTheme => DarkTheme.theme;
}

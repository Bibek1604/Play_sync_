import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLangKey = 'app_language';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;

  const AppLanguage({required this.code, required this.name, required this.nativeName});
}

const kSupportedLanguages = [
  AppLanguage(code: 'en', name: 'English', nativeName: 'English'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'ne', name: 'Nepali', nativeName: 'नेपाली'),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français'),
];

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(kSupportedLanguages.first) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey) ?? 'en';
    state = kSupportedLanguages.firstWhere((l) => l.code == code, orElse: () => kSupportedLanguages.first);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang.code);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) => LanguageNotifier());

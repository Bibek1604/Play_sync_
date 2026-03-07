import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';

/// Dynamic Theme Service
///
/// Resolves theme strictly from user/system preference.
final dynamicThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeProvider);
});

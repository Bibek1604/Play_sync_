import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';

/// Camera Theme Provider
/// 
/// A specialized provider that tracks whether the camera has detected "Darkness".
/// When darkness exceeds a threshold (e.g., finger over camera), it forces dark mode.
final cameraActiveProvider = StateProvider<bool>((ref) => false);
final cameraDarknessDetectedProvider = StateProvider<bool>((ref) => false);

/// Dynamic Theme Service
/// 
/// Intercepts the theme mode to favor Dark Mode when darkness is detected via selfie camera.
final dynamicThemeModeProvider = Provider<ThemeMode>((ref) {
  final isDarknessDetected = ref.watch(cameraDarknessDetectedProvider);
  final savedThemeMode = ref.watch(themeModeProvider);

  // If darkness is detected via camera (e.g. finger covered), force dark mode
  if (isDarknessDetected) {
    return ThemeMode.dark;
  }

  // Otherwise, revert to the user's saved preference
  return savedThemeMode;
});

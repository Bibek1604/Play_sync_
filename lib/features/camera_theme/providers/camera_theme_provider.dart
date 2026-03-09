import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/camera_visibility_controller.dart';
import '../../../app/theme/theme_provider.dart';

/// Camera Visibility Provider
/// Provides the camera visibility state to the app.
/// This is the main provider used throughout the app.
final cameraVisibilityProvider = StateNotifierProvider<
    CameraVisibilityController, CameraVisibilityState>((ref) {
  return CameraVisibilityController();
});

/// Camera Theme Manager
/// Listens to camera visibility changes and manages theme accordingly.
/// This provider connects camera visibility to theme changes.
/// BEHAVIOR:
/// - When camera is hidden → switch to dark mode
/// - When camera is shown → do NOT change theme (keep current state)
class CameraThemeManager {
  final Ref ref;
  bool _hasInitialized = false;

  CameraThemeManager(this.ref) {
    _initialize();
  }

  void _initialize() {
    if (_hasInitialized) return;
    _hasInitialized = true;

    // Listen to camera visibility changes
    ref.listen<CameraVisibilityState>(
      cameraVisibilityProvider,
      (previous, next) {
        _handleCameraVisibilityChange(previous, next);
      },
    );
  }

  /// Handle camera visibility changes
/// When camera becomes hidden → switch to dark mode
  /// When camera becomes visible → do NOTHING (keep current theme)
  void _handleCameraVisibilityChange(
    CameraVisibilityState? previous,
    CameraVisibilityState next,
  ) {
    // Camera was just hidden
    if (previous?.isVisible == true && next.isVisible == false) {
      _switchToDarkMode();
    }

    // Camera was just shown
    // IMPORTANT: We do NOT change theme here - it stays as is
    if (previous?.isVisible == false && next.isVisible == true) {
      // Do nothing - keep current theme state
    }
  }

  /// Switch app to dark mode
  void _switchToDarkMode() {
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final currentMode = ref.read(themeModeProvider);

    // Only switch if not already in dark mode
    if (currentMode != ThemeMode.dark) {
      themeModeNotifier.setThemeMode(ThemeMode.dark);
    }
  }
}

/// Camera Theme Manager Provider
/// Provides the camera theme manager instance.
/// This is kept alive to ensure the listener stays active.
final cameraThemeManagerProvider = Provider<CameraThemeManager>((ref) {
  return CameraThemeManager(ref);
});

/// Helper provider to check if camera is visible
final isCameraVisibleProvider = Provider<bool>((ref) {
  return ref.watch(cameraVisibilityProvider).isVisible;
});

/// Helper provider to check if camera is hidden
final isCameraHiddenProvider = Provider<bool>((ref) {
  return !ref.watch(cameraVisibilityProvider).isVisible;
});

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

/// Provider for managing dark mode based on selfie camera light sensor detection.
/// Uses the front camera to detect ambient light levels:
/// - If camera detects darkness: Enable dark mode
/// - If camera detects light: Keep light mode (default)
class CameraDarkModeNotifier extends StateNotifier<bool> {
  CameraDarkModeNotifier() : super(false) {
    // Start in light mode by default
    _initializeCameraSensorDetection();
  }

  Timer? _sensorCheckTimer;
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isEnabled = true; // Can be toggled by user
  bool _isStreaming = false;
  bool _allowNextSample = true;

  // Hysteresis avoids flickering theme around threshold.
  static const double _darkThreshold = 42.0;
  static const double _lightThreshold = 58.0;
  
  /// Initialize camera sensor detection for ambient light
  void _initializeCameraSensorDetection() async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      
      if (cameraStatus.isGranted) {
        debugPrint('[CameraDarkMode] Camera permission granted, initializing front camera');
        await _initializeFrontCamera();
      } else {
        debugPrint('[CameraDarkMode] Camera permission not granted, fallback to light mode');
        state = false; // Default to light mode
      }
    } catch (e) {
      debugPrint('[CameraDarkMode] Error initializing camera: $e');
      state = false; // Default to light mode on error
    }
  }

  /// Initialize front camera controller
  Future<void> _initializeFrontCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      
      // Find front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create camera controller with low resolution for better performance
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      _isInitialized = true;

      debugPrint('[CameraDarkMode] Front camera initialized successfully');
      
      // Start frame stream and periodic sampling gate.
      await _startImageStreamDetection();
      _startLightLevelDetection();
    } catch (e) {
      debugPrint('[CameraDarkMode] Failed to initialize front camera: $e');
      _isInitialized = false;
      state = false; // Fallback to light mode
    }
  }

  /// Start periodic checks for ambient light level via camera
  void _startLightLevelDetection() {
    if (!_isInitialized || _cameraController == null) return;

    // Only allow one luminance sample every 2 seconds.
    _sensorCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _allowNextSample = _isEnabled;
    });
  }

  Future<void> _startImageStreamDetection() async {
    if (_cameraController == null || _isStreaming) return;
    try {
      await _cameraController!.startImageStream((CameraImage image) {
        if (!_isEnabled || !_allowNextSample) return;
        _allowNextSample = false;
        _detectAmbientLightFromImage(image);
      });
      _isStreaming = true;
    } catch (e) {
      debugPrint('[CameraDarkMode] Failed to start image stream: $e');
      _isStreaming = false;
    }
  }

  /// Detect ambient light level using selfie camera luminance (Y plane).
  void _detectAmbientLightFromImage(CameraImage image) {
    try {
      if (image.planes.isEmpty) return;
      final Uint8List yBytes = image.planes.first.bytes;
      if (yBytes.isEmpty) return;

      // Sample bytes sparsely for performance.
      final int step = math.max(1, yBytes.length ~/ 1800);
      int sum = 0;
      int count = 0;
      for (int i = 0; i < yBytes.length; i += step) {
        sum += yBytes[i];
        count++;
      }
      if (count == 0) return;

      final double avgLuma = sum / count; // 0..255 (lower = darker)

      bool newDark = state;
      if (!state && avgLuma < _darkThreshold) {
        newDark = true;
      } else if (state && avgLuma > _lightThreshold) {
        newDark = false;
      }

      if (newDark != state) {
        state = newDark;
        debugPrint(
          '[CameraDarkMode] Ambient light changed: ${newDark ? 'DARK' : 'LIGHT'} '
          '(luma: ${avgLuma.toStringAsFixed(1)})',
        );
      }
    } catch (e) {
      debugPrint('[CameraDarkMode] Error detecting light: $e');
    }
  }

  /// Enable or disable camera-based dark mode detection
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      // When disabled, default to light mode
      state = false;
      debugPrint('[CameraDarkMode] Sensor detection disabled, switching to light mode');
    }
  }

  /// Manual method to toggle dark mode (for testing/UX override)
  void setDarkMode(bool isDark) {
    state = isDark;
  }

  /// Get current dark mode state
  bool isDarkMode() => state;

  @override
  void dispose() {
    _sensorCheckTimer?.cancel();
    if (_cameraController != null && _isStreaming) {
      unawaited(_cameraController!.stopImageStream());
    }
    _cameraController?.dispose();
    super.dispose();
  }

  /// Manually toggle dark mode (for user override)
  void toggleDarkMode() {
    state = !state;
  }
}

/// Provider for camera-based dark mode detection
final cameraDarkModeProvider = StateNotifierProvider<CameraDarkModeNotifier, bool>((ref) {
  return CameraDarkModeNotifier();
});

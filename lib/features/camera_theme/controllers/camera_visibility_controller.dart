import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Camera Visibility State
/// Manages the visibility state of the camera screen.
/// This is separate from UI to maintain clean architecture.
class CameraVisibilityState {
  final bool isVisible;
  final DateTime? lastHiddenAt;
  final DateTime? lastShownAt;

  const CameraVisibilityState({
    required this.isVisible,
    this.lastHiddenAt,
    this.lastShownAt,
  });

  factory CameraVisibilityState.initial() {
    return const CameraVisibilityState(
      isVisible: true,
      lastHiddenAt: null,
      lastShownAt: null,
    );
  }

  CameraVisibilityState copyWith({
    bool? isVisible,
    DateTime? lastHiddenAt,
    DateTime? lastShownAt,
  }) {
    return CameraVisibilityState(
      isVisible: isVisible ?? this.isVisible,
      lastHiddenAt: lastHiddenAt ?? this.lastHiddenAt,
      lastShownAt: lastShownAt ?? this.lastShownAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraVisibilityState &&
        other.isVisible == isVisible &&
        other.lastHiddenAt == lastHiddenAt &&
        other.lastShownAt == lastShownAt;
  }

  @override
  int get hashCode {
    return Object.hash(isVisible, lastHiddenAt, lastShownAt);
  }
}

/// Camera Visibility Controller
/// Controls the visibility state of the camera screen.
/// Follows clean architecture - business logic only, no UI concerns.
class CameraVisibilityController
    extends StateNotifier<CameraVisibilityState> {
  CameraVisibilityController() : super(CameraVisibilityState.initial());

  /// Hide the camera
/// Sets visibility to false and records the timestamp.
  /// This will trigger theme change through the camera theme provider.
  void hideCamera() {
    if (state.isVisible) {
      state = state.copyWith(
        isVisible: false,
        lastHiddenAt: DateTime.now(),
      );
    }
  }

  /// Show the camera
/// Sets visibility to true and records the timestamp.
  /// IMPORTANT: This does NOT change the theme - theme stays as is.
  void showCamera() {
    if (!state.isVisible) {
      state = state.copyWith(
        isVisible: true,
        lastShownAt: DateTime.now(),
      );
    }
  }

  /// Toggle camera visibility
  void toggleVisibility() {
    if (state.isVisible) {
      hideCamera();
    } else {
      showCamera();
    }
  }

  /// Reset to initial state (camera visible)
  void reset() {
    state = CameraVisibilityState.initial();
  }

  /// Check if camera is currently visible
  bool get isVisible => state.isVisible;

  /// Check if camera is currently hidden
  bool get isHidden => !state.isVisible;
}

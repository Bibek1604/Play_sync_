import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Device haptic feedback helpers.
class HapticService {
  HapticService._();

  /// Light tap — use for button presses.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Medium bump — use for confirmations.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Heavy thud — use for destructive actions or errors.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Selection click — use for toggle switches, selects.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Success pattern: light → light (double tap feel).
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Error pattern: heavy → medium.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }
}

/// Extension on BuildContext for quick haptic access.
extension HapticContext on BuildContext {
  void hapticLight() => HapticService.light();
  void hapticSuccess() => HapticService.success();
  void hapticError() => HapticService.error();
}

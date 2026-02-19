import 'package:flutter/material.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/services/sound_manager.dart';

/// Custom Snackbar
/// 
/// Premium branded notifications with sound feedback
class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    bool playSound = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Play sound based on type
    if (playSound) {
      switch (type) {
        case SnackbarType.success:
          SoundManager.instance.playSuccess();
          break;
        case SnackbarType.error:
          SoundManager.instance.playError();
          break;
        case SnackbarType.warning:
          SoundManager.instance.playWarning();
          break;
        case SnackbarType.info:
          SoundManager.instance.playInfo();
          break;
      }
    }

    // Get colors based on type
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData icon;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = AppColors.statusSuccess;
        icon = Icons.check_circle;
        break;
      case SnackbarType.error:
        backgroundColor = AppColors.statusError;
        icon = Icons.error;
        break;
      case SnackbarType.warning:
        backgroundColor = AppColors.statusWarning;
        textColor = AppColors.slate900;
        icon = Icons.warning;
        break;
      case SnackbarType.info:
        backgroundColor = AppColors.emerald500;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            AppSpacing.gapHorizontalMD,
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.card,
        ),
        margin: AppSpacing.paddingMD,
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackbarType.info);
  }
}

enum SnackbarType {
  success,
  error,
  warning,
  info,
}

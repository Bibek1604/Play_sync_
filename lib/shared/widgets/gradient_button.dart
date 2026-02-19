import 'package:flutter/material.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_shadows.dart';

/// Premium Gradient Button
/// 
/// Matches web version with emerald→teal gradient and glow effect
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final ButtonSize size;
  final bool useGradient;
  
  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.size = ButtonSize.medium,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Button dimensions based on size
    final double height = size == ButtonSize.small
        ? AppSpacing.buttonHeightSmall
        : size == ButtonSize.large
            ? AppSpacing.buttonHeightLarge
            : AppSpacing.buttonHeightMedium;

    final EdgeInsets padding = size == ButtonSize.small
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)
        : size == ButtonSize.large
            ? AppSpacing.buttonPaddingLarge
            : AppSpacing.buttonPadding;

    final bool isEnabled = onPressed != null && !isLoading;

    return Container(
      height: height,
      width: isFullWidth ? double.infinity : null,
      decoration: isEnabled && useGradient
          ? BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppBorderRadius.button,
              boxShadow: AppShadows.emeraldGlow,
            )
          : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: useGradient ? Colors.transparent : AppColors.emerald500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? AppColors.slate700
              : AppColors.slate300,
          disabledForegroundColor: isDark
              ? AppColors.slate500
              : AppColors.slate400,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
          minimumSize: Size(isFullWidth ? double.infinity : 88, height),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              )
            : Row(
                mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    AppSpacing.gapHorizontalSM,
                  ],
                  Text(
                    text.toUpperCase(),
                    style: size == ButtonSize.large
                        ? AppTypography.buttonLarge
                        : AppTypography.button,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Outlined Premium Button
class OutlinedPremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final ButtonSize size;

  const OutlinedPremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final double height = size == ButtonSize.small
        ? AppSpacing.buttonHeightSmall
        : size == ButtonSize.large
            ? AppSpacing.buttonHeightLarge
            : AppSpacing.buttonHeightMedium;

    final EdgeInsets padding = size == ButtonSize.small
        ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)
        : size == ButtonSize.large
            ? AppSpacing.buttonPaddingLarge
            : AppSpacing.buttonPadding;

    final bool isEnabled = onPressed != null && !isLoading;

    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.emerald500,
        disabledForegroundColor: isDark
            ? AppColors.slate600
            : AppColors.slate400,
        side: BorderSide(
          color: isEnabled
              ? AppColors.emerald500
              : (isDark ? AppColors.slate700 : AppColors.slate300),
          width: 1.5,
        ),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.button,
        ),
        minimumSize: Size(isFullWidth ? double.infinity : 88, height),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.emerald500.withOpacity(0.8),
                ),
              ),
            )
          : Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  AppSpacing.gapHorizontalSM,
                ],
                Text(
                  text.toUpperCase(),
                  style: size == ButtonSize.large
                      ? AppTypography.buttonLarge
                      : AppTypography.button,
                ),
              ],
            ),
    );
  }
}

/// Button size enum
enum ButtonSize {
  small,
  medium,
  large,
}

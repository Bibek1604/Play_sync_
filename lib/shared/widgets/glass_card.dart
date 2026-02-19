import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_shadows.dart';

/// Glassmorphism Card
/// 
/// Premium glass effect with backdrop blur matching web version
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool hasBorder;
  final bool useGradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.onTap,
    this.hasBorder = true,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final effectivePadding = padding ?? AppSpacing.paddingMD;
    final effectiveBorderRadius = borderRadius ?? AppBorderRadius.card;

    Widget content = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          padding: effectivePadding,
          decoration: BoxDecoration(
            gradient: useGradient
                ? (isDark
                    ? AppColors.cardGradientDark
                    : AppColors.cardGradientLight)
                : null,
            color: useGradient
                ? null
                : (isDark
                    ? AppColors.glassBackdropDark
                    : AppColors.glassBackdropLight),
            borderRadius: effectiveBorderRadius,
            border: hasBorder
                ? Border.all(
                    color: isDark
                        ? AppColors.borderDefaultDark.withOpacity(0.2)
                        : AppColors.borderDefaultLight.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: isDark ? AppShadows.mdDark : AppShadows.md,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}

/// Premium Card (non-glass, solid with shadow)
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool hasBorder;
  final bool hasGradientBorder;
  final Color? backgroundColor;
  final List<BoxShadow>? customShadows;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.height,
    this.onTap,
    this.hasBorder = true,
    this.hasGradientBorder = false,
    this.backgroundColor,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final effectivePadding = padding ?? AppSpacing.paddingMD;
    final effectiveBorderRadius = borderRadius ?? AppBorderRadius.card;
    final effectiveBackgroundColor = backgroundColor ??
        (isDark
            ? AppColors.backgroundSecondaryDark
            : AppColors.backgroundPrimaryLight);

    Widget content = Container(
      width: width,
      height: height,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        border: hasBorder && !hasGradientBorder
            ? Border.all(
                color: isDark
                    ? AppColors.borderDefaultDark
                    : AppColors.borderDefaultLight,
                width: 1,
              )
            : null,
        boxShadow: customShadows ?? (isDark ? AppShadows.mdDark : AppShadows.md),
      ),
      child: child,
    );

    // Gradient border effect
    if (hasGradientBorder) {
      content = Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: effectiveBorderRadius,
        ),
        padding: const EdgeInsets.all(2), // Border width
        child: Container(
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: effectiveBorderRadius,
          ),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}

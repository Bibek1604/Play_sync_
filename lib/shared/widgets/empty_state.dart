import 'package:flutter/material.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';

/// Empty State Widget
/// 
/// Displays when no data is available
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient.scale(0.1),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDefaultDark
                      : AppColors.borderDefaultLight,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.emerald500,
              ),
            ),
            AppSpacing.gapVerticalXL,
            Text(
              title,
              style: AppTypography.h2.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.gapVerticalMD,
              Text(
                message!,
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.gapVerticalXL,
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.button,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.actionLabel = 'Retry',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.statusError.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.statusError.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.statusError,
              ),
            ),
            AppSpacing.gapVerticalXL,
            Text(
              title,
              style: AppTypography.h2.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.gapVerticalMD,
              Text(
                message!,
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.gapVerticalXL,
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.button,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

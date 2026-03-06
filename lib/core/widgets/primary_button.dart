import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable Primary Button Widget
/// Matches web sign-in button style for consistency
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final EdgeInsets padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null && !isLoading) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Secondary Button - For secondary actions
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null && !isLoading) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

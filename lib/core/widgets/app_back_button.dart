import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable back button widget for internal pages.
/// Displays a blue back-arrow icon with optional label text.
/// Place in the AppBar `leading` slot or as a standalone widget.
class AppBackButton extends StatelessWidget {
  /// Optional label text shown beside the arrow (e.g. "Back").
  final String? label;

  /// Override the default pop action.
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

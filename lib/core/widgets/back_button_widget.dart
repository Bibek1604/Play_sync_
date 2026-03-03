import 'package:flutter/material.dart';

/// A consistent, visible back button widget that appears on internal pages.
/// Positioned top-left with icon + label for clear navigation.
class BackButtonWidget extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;

  const BackButtonWidget({
    super.key,
    this.label,
    this.onPressed,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor = color ?? (isDark ? Colors.white : Colors.black87);
    final defaultBgColor = backgroundColor ??
        (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: defaultBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: defaultColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: defaultColor,
              ),
              if (label != null && label!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: defaultColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

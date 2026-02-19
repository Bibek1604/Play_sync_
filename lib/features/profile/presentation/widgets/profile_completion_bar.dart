import 'package:flutter/material.dart';

/// Animated horizontal progress bar showing profile completion percentage.
class ProfileCompletionBar extends StatelessWidget {
  final int percent; // 0–100
  final bool showLabel;

  const ProfileCompletionBar({
    super.key,
    required this.percent,
    this.showLabel = true,
  });

  Color get _color {
    if (percent >= 80) return const Color(0xFF38A169);
    if (percent >= 50) return const Color(0xFFD69E2E);
    return const Color(0xFFE53E3E);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile completion',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent / 100),
            duration: const Duration(milliseconds: 600),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: _color,
            ),
          ),
        ),
      ],
    );
  }
}

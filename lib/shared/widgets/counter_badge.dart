import 'package:flutter/material.dart';

/// A small circular badge with a count. Shows "99+" for counts > 99.
/// Wraps any widget (icon, avatar, etc.) and positions the badge top-right.
class CounterBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final bool show;

  const CounterBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show || count <= 0) return child;

    final bg = badgeColor ?? const Color(0xFFE53E3E);
    final fg = textColor ?? Colors.white;
    final label = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: AnimatedScale(
            scale: count > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

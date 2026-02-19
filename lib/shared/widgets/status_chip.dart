import 'package:flutter/material.dart';

/// A styled status chip used to display game or player status.
/// Automatically chooses icon and color from [AppStatusChipStyle].
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 11,
  });

  factory StatusChip.open() => const StatusChip(
        label: 'OPEN',
        color: Color(0xFF38A169),
        icon: Icons.lock_open_rounded,
      );

  factory StatusChip.full() => const StatusChip(
        label: 'FULL',
        color: Color(0xFFD69E2E),
        icon: Icons.people_rounded,
      );

  factory StatusChip.ended() => const StatusChip(
        label: 'ENDED',
        color: Color(0xFF718096),
        icon: Icons.flag_rounded,
      );

  factory StatusChip.cancelled() => const StatusChip(
        label: 'CANCELLED',
        color: Color(0xFFE53E3E),
        icon: Icons.cancel_rounded,
      );

  factory StatusChip.online() => const StatusChip(
        label: 'ONLINE',
        color: Color(0xFF3182CE),
        icon: Icons.wifi_rounded,
      );

  factory StatusChip.offline() => const StatusChip(
        label: 'OFFLINE',
        color: Color(0xFF718096),
        icon: Icons.wifi_off_rounded,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

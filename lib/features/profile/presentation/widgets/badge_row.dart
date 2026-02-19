import 'package:flutter/material.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_badge.dart';

/// Horizontal scrollable row of badge chips.
class BadgeRow extends StatelessWidget {
  final List<ProfileBadge> badges;

  const BadgeRow({super.key, required this.badges});

  static const _rarityColors = {
    BadgeRarity.common: Color(0xFF718096),
    BadgeRarity.rare: Color(0xFF3182CE),
    BadgeRarity.epic: Color(0xFF805AD5),
    BadgeRarity.legendary: Color(0xFFD69E2E),
  };

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Text(
        'No badges yet — play games to earn them!',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final badge = badges[i];
          final color =
              _rarityColors[badge.rarity] ?? const Color(0xFF718096);
          return Tooltip(
            message: badge.description,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconData(
                      int.tryParse(badge.iconCode, radix: 16) ?? 0xe000,
                      fontFamily: 'MaterialIcons',
                    ),
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

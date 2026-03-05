import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated podium showing top-3 players with height variation.
class LeaderboardPodium extends StatelessWidget {
  final String firstUsername;
  final String secondUsername;
  final String thirdUsername;
  final String? firstAvatarUrl;
  final String? secondAvatarUrl;
  final String? thirdAvatarUrl;
  final int firstPoints;
  final int secondPoints;
  final int thirdPoints;

  const LeaderboardPodium({
    super.key,
    required this.firstUsername,
    required this.secondUsername,
    required this.thirdUsername,
    this.firstAvatarUrl,
    this.secondAvatarUrl,
    this.thirdAvatarUrl,
    required this.firstPoints,
    required this.secondPoints,
    required this.thirdPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumSlot(
              rank: 2,
              username: secondUsername,
              points: secondPoints,
              avatarUrl: secondAvatarUrl,
              height: 100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumSlot(
              rank: 1,
              username: firstUsername,
              points: firstPoints,
              avatarUrl: firstAvatarUrl,
              height: 140,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PodiumSlot(
              rank: 3,
              username: thirdUsername,
              points: thirdPoints,
              avatarUrl: thirdAvatarUrl,
              height: 80,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final int rank;
  final String username;
  final int points;
  final String? avatarUrl;
  final double height;

  const _PodiumSlot({
    required this.rank,
    required this.username,
    required this.points,
    required this.height,
    this.avatarUrl,
  });

  static const _colors = [
    AppColors.primary,
    Color(0xFF94A3B8), // Slate 400
    Color(0xFF92400E), // Amber 800 (Bronze)
  ];

  @override
  Widget build(BuildContext context) {
    final bool isFirst = rank == 1;
    final color = _colors[rank - 1];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isFirst ? 3 : 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.4)],
                ),
              ),
              child: CircleAvatar(
                radius: isFirst ? 34 : 28,
                backgroundColor: AppColors.surface,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(
                        username[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isFirst ? 20 : 16,
                          color: color,
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          username,
          style: TextStyle(
            fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
            fontSize: isFirst ? 14 : 12,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          '${points.toString()} XP',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
              left: BorderSide(color: color.withValues(alpha: 0.1), width: 1),
              right: BorderSide(color: color.withValues(alpha: 0.1), width: 1),
            ),
          ),
          child: isFirst
              ? Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: color.withValues(alpha: 0.4),
                    size: 32,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

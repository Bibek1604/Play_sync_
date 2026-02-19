import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumSlot(rank: 2, username: secondUsername, points: secondPoints, avatarUrl: secondAvatarUrl, height: 90)),
          Expanded(child: _PodiumSlot(rank: 1, username: firstUsername, points: firstPoints, avatarUrl: firstAvatarUrl, height: 120)),
          Expanded(child: _PodiumSlot(rank: 3, username: thirdUsername, points: thirdPoints, avatarUrl: thirdAvatarUrl, height: 70)),
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

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _colors = [AppColors.emerald500, Color(0xFFC0C0C0), Color(0xFFCD7F32)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 30 : 24,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          backgroundColor: _colors[rank - 1].withOpacity(0.2),
          child: avatarUrl == null
              ? Text(username[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: rank == 1 ? 18 : 14, color: _colors[rank - 1]))
              : null,
        ),
        const SizedBox(height: 4),
        Text(_medals[rank - 1], style: const TextStyle(fontSize: 16)),
        Text(username, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
        Text('$points pts', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: _colors[rank - 1].withOpacity(0.2),
            border: Border(top: BorderSide(color: _colors[rank - 1], width: 2)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }
}

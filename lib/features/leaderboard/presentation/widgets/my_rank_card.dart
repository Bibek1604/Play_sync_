import 'package:flutter/material.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../../../app/theme/app_colors.dart';
import 'streak_badge.dart';

/// Card showing the current user's own rank and stats in the leaderboard.
class MyRankCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const MyRankCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.emerald500.withOpacity(0.8), AppColors.emerald500.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.emerald500.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: entry.profileImageUrl != null ? NetworkImage(entry.profileImageUrl!) : null,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: entry.profileImageUrl == null
                ? Text(entry.username[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rank', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                Row(
                  children: [
                    Text('#${entry.rank}', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    StreakBadge(streak: entry.currentStreak),
                  ],
                ),
                Text(entry.username, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalPoints}', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('points', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60)),
              const SizedBox(height: 4),
              Text('${(entry.winRate * 100).toStringAsFixed(0)}% WR', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

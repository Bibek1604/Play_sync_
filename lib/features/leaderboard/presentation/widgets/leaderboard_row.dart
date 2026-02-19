import 'package:flutter/material.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../../../shared/theme/app_colors.dart';

/// A single animated leaderboard row widget.
class LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final VoidCallback? onTap;

  const LeaderboardRow({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = entry.rank <= 3;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: entry.isCurrentUser
              ? AppColors.emerald500.withOpacity(0.12)
              : theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: entry.isCurrentUser
              ? Border.all(color: AppColors.emerald500, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            _RankBadge(rank: entry.rank, isTop3: isTop3),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: entry.profileImageUrl != null
                  ? NetworkImage(entry.profileImageUrl!)
                  : null,
              child: entry.profileImageUrl == null
                  ? Text(entry.username[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.gamesWon}W · ${(entry.winRate * 100).toStringAsFixed(0)}% WR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalPoints}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTop3 ? AppColors.emerald500 : null,
                  ),
                ),
                Text(
                  'pts',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isTop3;

  const _RankBadge({required this.rank, required this.isTop3});

  @override
  Widget build(BuildContext context) {
    if (isTop3) {
      const medals = ['🥇', '🥈', '🥉'];
      return SizedBox(
        width: 28,
        child: Text(medals[rank - 1], style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
      );
    }
    return SizedBox(
      width: 28,
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

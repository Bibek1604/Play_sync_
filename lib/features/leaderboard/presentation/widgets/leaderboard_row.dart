import 'package:flutter/material.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../../../core/constants/app_colors.dart';

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
              ? AppColors.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: entry.isCurrentUser
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            _RankBadge(rank: entry.rank, isTop3: isTop3),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: entry.avatar != null && entry.avatar!.isNotEmpty
                  ? NetworkImage(entry.avatar!)
                  : null,
              child: entry.avatar == null || entry.avatar!.isEmpty
                  ? Text(entry.initials,
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.fullName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${entry.wins}W · ${(entry.winRate * 100).toStringAsFixed(0)}% WR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.xp}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTop3 ? AppColors.primary : null,
                  ),
                ),
                Text(
                  'pts',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

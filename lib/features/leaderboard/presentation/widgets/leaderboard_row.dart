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
    final bool isCurrentUser = entry.isCurrentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrentUser
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.05),
              width: isCurrentUser ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: entry.rank <= 3
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: entry.avatar != null && entry.avatar!.isNotEmpty
                        ? NetworkImage(entry.avatar!)
                        : null,
                    child: entry.avatar == null || entry.avatar!.isEmpty
                        ? Text(
                            entry.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  if (isCurrentUser)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.emoji_events_rounded,
                          label: '${entry.wins} Wins',
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.bolt_rounded,
                          label: '${(entry.winRate * 100).toStringAsFixed(0)}%',
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.xp.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'XP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
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

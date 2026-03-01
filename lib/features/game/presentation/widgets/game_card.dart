import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/game_entity.dart';

/// Professional game card with green theme design.
class GameCard extends StatelessWidget {
  final GameEntity game;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const GameCard({super.key, required this.game, this.onTap, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category icon, title, status
              Row(
                children: [
                  _CategoryIcon(category: game.category),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      game.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _StatusChip(status: game.status),
                ],
              ),

              // Description
              if (game.description.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  game.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: AppSpacing.md),

              // Info row: location/online, players, date
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _InfoItem(
                    icon: game.isOnline ? Icons.wifi : Icons.location_on_outlined,
                    text: game.isOnline ? 'Online' : (game.location ?? 'Location TBD'),
                    color: AppColors.primary,
                  ),
                  _InfoItem(
                    icon: Icons.group_outlined,
                    text: '${game.currentPlayers}/${game.maxPlayers}',
                    color: game.isFull ? AppColors.error : AppColors.textSecondary,
                  ),
                  _InfoItem(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(game.scheduledAt),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              // Join button (if game is not full and upcoming)
              if (!game.isFull &&
                  game.status == GameStatus.upcoming &&
                  onJoin != null) ...[
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login, size: 18),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Join • ${game.spotsLeft} spots left',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now);
    if (diff.inDays == 0) {
      final h = diff.inHours;
      if (h <= 0) return 'Starting now';
      if (h < 2) return 'In ${diff.inMinutes}min';
      return 'In ${h}h';
    }
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) {
      final daysAgo = -diff.inDays;
      return daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago';
    }
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return _shortDate(d);
  }

  String _shortDate(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}

/// Info item widget for location, players, date
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: AppSpacing.xs),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

/// Category icon with professional design
class _CategoryIcon extends StatelessWidget {
  final GameCategory category;
  const _CategoryIcon({required this.category});

  IconData get icon => switch (category) {
        GameCategory.football => Icons.sports_soccer,
        GameCategory.basketball => Icons.sports_basketball,
        GameCategory.cricket => Icons.sports_cricket,
        GameCategory.tennis => Icons.sports_tennis,
        GameCategory.badminton => Icons.sports,
        GameCategory.chess => Icons.extension,
        GameCategory.other => Icons.sports_esports,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryWithOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 22, color: AppColors.primary),
    );
  }
}

/// Status chip with color-coded design
class _StatusChip extends StatelessWidget {
  final GameStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      GameStatus.upcoming => ('Upcoming', AppColors.info.withOpacity(0.12), AppColors.info),
      GameStatus.live => ('LIVE', AppColors.error.withOpacity(0.12), AppColors.error),
      GameStatus.completed => ('Completed', AppColors.textTertiary.withOpacity(0.12), AppColors.textSecondary),
      GameStatus.cancelled => ('Cancelled', AppColors.warning.withOpacity(0.12), AppColors.warning),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

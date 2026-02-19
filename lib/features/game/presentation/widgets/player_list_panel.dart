import 'package:flutter/material.dart';
import 'package:play_sync_new/features/game/domain/entities/player.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';

/// Player List Panel
/// 
/// Shows all players in the current game
class PlayerListPanel extends StatelessWidget {
  final List<Player> players;
  final int maxPlayers;
  final String hostId;

  const PlayerListPanel({
    super.key,
    required this.players,
    required this.maxPlayers,
    required this.hostId,
  });

  @override
  Widget build(BuildContext context) {
    final emptySlots = maxPlayers - players.length;

    return GlassCard(
      margin: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Players',
                style: AppTypography.h3,
              ),
              AppSpacing.gapHorizontalSM,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppBorderRadius.chip,
                ),
                child: Text(
                  '${players.length}/$maxPlayers',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMD,
          
          // Player List
          Expanded(
            child: ListView.builder(
              itemCount: players.length + emptySlots,
              itemBuilder: (context, index) {
                if (index < players.length) {
                  final player = players[index];
                  final isHost = player.id == hostId;
                  
                  return _PlayerListItem(
                    player: player,
                    isHost: isHost,
                  );
                } else {
                  return _EmptySlot();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerListItem extends StatelessWidget {
  final Player player;
  final bool isHost;

  const _PlayerListItem({
    required this.player,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundSecondaryDark.withOpacity(0.5)
            : AppColors.backgroundSecondaryLight.withOpacity(0.5),
        borderRadius: AppBorderRadius.card,
        border: isHost
            ? Border.all(color: AppColors.emerald500, width: 2)
            : null,
      ),
      child: Row(
        children: [
          PlayerAvatar(
            imageUrl: player.avatar,
            name: player.username,
            size: AppSpacing.avatarSmall,
            showOnlineStatus: true,
            isOnline: player.isOnline,
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.username ?? 'Player',
                        style: AppTypography.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHost) ...[
                      AppSpacing.gapHorizontalSM,
                      Icon(
                        Icons.star,
                        color: AppColors.statusWarning,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                if (player.score > 0) ...[
                  AppSpacing.gapVerticalXS,
                  Text(
                    '${player.score} points',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundSecondaryDark.withOpacity(0.3)
            : AppColors.backgroundSecondaryLight.withOpacity(0.3),
        borderRadius: AppBorderRadius.card,
        border: Border.all(
          color: isDark
              ? AppColors.borderDefaultDark
              : AppColors.borderDefaultLight,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.avatarSmall,
            height: AppSpacing.avatarSmall,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? AppColors.slate700
                  : AppColors.slate300,
            ),
            child: Center(
              child: Icon(
                Icons.person_add_outlined,
                color: isDark
                    ? AppColors.slate500
                    : AppColors.slate400,
                size: 20,
              ),
            ),
          ),
          AppSpacing.gapHorizontalMD,
          Text(
            'Waiting for player...',
            style: AppTypography.body.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

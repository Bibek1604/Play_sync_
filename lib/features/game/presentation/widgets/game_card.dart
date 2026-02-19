import 'package:flutter/material.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';

/// Game Card Widget
/// 
/// Displays game information in the lobby.
/// – Creator  → shows Delete + Chat buttons
/// – Member   → shows Chat button
/// – Other    → shows Join button (or FULL badge)
class GameCard extends StatelessWidget {
  final Game game;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onDelete;
  final VoidCallback? onChat;

  const GameCard({
    super.key,
    required this.game,
    this.currentUserId = '',
    this.onTap,
    this.onJoin,
    this.onDelete,
    this.onChat,
  });

  bool get _isCreator => game.creatorId == currentUserId && currentUserId.isNotEmpty;
  bool get _isMember  => !_isCreator &&
      game.participants.any((p) => p.id == currentUserId) &&
      currentUserId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game Image Header (if available)
          if (game.imageUrl != null && game.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                game.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Icon(
                      Icons.gamepad,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: isDark ? AppColors.backgroundSecondaryDark : AppColors.backgroundSecondaryLight,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Padding for content below image
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Game Icon (only show if no image)
                    if (game.imageUrl == null || game.imageUrl!.isEmpty)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: AppBorderRadius.card,
                        ),
                        child: const Icon(
                          Icons.gamepad,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    if (game.imageUrl == null || game.imageUrl!.isEmpty)
                      AppSpacing.gapHorizontalMD,
                    
                    // Game Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: AppTypography.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.gapVerticalXS,
                          Text(
                            _getStatusText(),
                            style: AppTypography.caption.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge (hide for open/waiting games — shown in subtitle)
                    if (game.status != GameStatus.open)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.2),
                          borderRadius: AppBorderRadius.chip,
                          border: Border.all(
                            color: _getStatusColor(),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          game.status.name.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapVerticalMD,
                
                // Description (if available)
                if (game.description != null && game.description!.isNotEmpty) ...[
                  Text(
                    game.description!,
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.gapVerticalMD,
                ],
                
                // Tags (if available)
                if (game.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.emerald500.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.emerald500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  AppSpacing.gapVerticalMD,
                ],
                
                // Players Info
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      '${game.currentPlayers}/${game.maxPlayers} Players',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    
                    // ── Action Buttons (depends on game status) ─────────
                    // Ended or Cancelled: no interactions allowed
                    if (game.status == GameStatus.ended ||
                        game.status == GameStatus.cancelled) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.15),
                          borderRadius: AppBorderRadius.chip,
                          border: Border.all(color: _getStatusColor().withOpacity(0.4)),
                        ),
                        child: Text(
                          game.status == GameStatus.ended
                              ? 'GAME ENDED'
                              : 'CANCELLED',
                          style: AppTypography.caption.copyWith(
                            color: _getStatusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                    // ── Creator: Delete + Chat ──────────────────────────
                    else if (_isCreator) ...[
                      // Chat button
                      if (onChat != null)
                        OutlinedButton.icon(
                          onPressed: onChat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                      if (onChat != null) AppSpacing.gapHorizontalSM,
                      // Delete button
                      if (onDelete != null)
                        ElevatedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusError,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ]
                    // ── Already a member: Chat ──────────────────────────
                    else if (_isMember) ...[
                      if (onChat != null)
                        ElevatedButton.icon(
                          onPressed: onChat,
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ]
                    // ── Other user: show FULL badge inline when full ─────
                    else if (game.isFull) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusError.withOpacity(0.2),
                          borderRadius: AppBorderRadius.chip,
                        ),
                        child: Text(
                          'FULL',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.statusError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Full-width Join button (non-member, non-creator, open game) ──
                if (!_isCreator &&
                    !_isMember &&
                    game.status != GameStatus.ended &&
                    game.status != GameStatus.cancelled &&
                    !game.isFull) ...[
                  AppSpacing.gapVerticalMD,
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.login_rounded, size: 20),
                      label: const Text('Join Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  String _getStatusText() {
    switch (game.status) {
      case GameStatus.open:
        return 'Waiting for players';
      case GameStatus.full:
        return 'Game full';
      case GameStatus.ended:
        return 'Finished';
      case GameStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor() {
    switch (game.status) {
      case GameStatus.open:
        return AppColors.emerald500;
      case GameStatus.full:
        return AppColors.statusWarning;
      case GameStatus.ended:
        return AppColors.textSecondaryLight;
      case GameStatus.cancelled:
        return AppColors.statusError;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game_chat/game_chat.dart';

/// GameCard — shows game info with state-driven action buttons.
///
/// Button logic (state-driven, never error-driven):
///   • Creator + OPEN  → "Go to Chat" + "Cancel Game"
///   • Participant (not creator) + OPEN → "Go to Chat" + "Leave Game"
///   • Not joined + OPEN + not full → "Join Game"
///   • Not joined + OPEN + full → "Game Full" (disabled)
///   • ENDED   → "View Results"
///   • CANCELLED → badge only, no action
///
/// [isAlreadyJoined] — override from parent: true when the game appears in
/// myJoinedGames or myCreatedGames even if participant list isn't populated.
class GameCard extends StatelessWidget {
  final GameEntity game;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  /// External override: set to true when the parent knows the user has already
  /// joined (e.g., by checking myJoinedGames/myCreatedGames lists).
  final bool isAlreadyJoined;
  /// External override: set to true when the parent knows the user CREATED this
  /// game (i.e., the game appears in myCreatedGames). This is the most reliable
  /// check because game list endpoints don't always populate creatorId.
  final bool isAlreadyCreator;

  const GameCard({
    super.key,
    required this.game,
    this.currentUserId,
    this.onTap,
    this.onJoin,
    this.onLeave,
    this.onCancel,
    this.onDelete,
    this.isAlreadyJoined = false,
    this.isAlreadyCreator = false,
  });

  /// Creator check: prefer the reliable server-backed flag, fall back to local field.
  bool get _isCreator =>
      isAlreadyCreator ||
      (currentUserId != null && game.isCreator(currentUserId!));

  bool get _isParticipant =>
      currentUserId != null && game.isParticipant(currentUserId!);

  /// Whether the current user is involved in the game (creator or participant).
  /// Prefers [isAlreadyJoined] override, then falls back to participant list check.
  bool get _isJoined => isAlreadyJoined || _isCreator || _isParticipant;

  @override
  Widget build(BuildContext context) {
    if (currentUserId != null && (game.isCreator(currentUserId!) || isAlreadyCreator)) {
      debugPrint('[GameCard] Detected CREATOR for ${game.title}: currentUserId=$currentUserId, game.creatorId=${game.creatorId}, isAlreadyCreator=$isAlreadyCreator');
    }
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      color: theme.cardColor,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (_isJoined) {
                onTap?.call();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Join game first to view game details.'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Game Image / Placeholder ──────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: game.imageUrl != null && game.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: game.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.dividerColor,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => _GameImagePlaceholder(
                                sport: game.sport,
                              ),
                            )
                          : _GameImagePlaceholder(sport: game.sport),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      _SportIcon(sport: game.sport),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (game.creatorName.isNotEmpty)
                              Row(
                                children: [
                                  Text(
                                    'by ${game.creatorName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  if (_isCreator) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('YOU', style: TextStyle(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.bold, 
                                        color: theme.colorScheme.primary
                                      )),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Leave space for the delete icon when creator
                      if (_isCreator) const SizedBox(width: 38),
                      const SizedBox(width: 8),
                      _CategoryChip(category: game.category),
                      const SizedBox(width: 6),
                      _StatusChip(status: game.status),
                    ],
                  ),

                  // ── Description ──────────────────────────────────────
                  if (game.description.isNotEmpty) ...[  
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      game.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: AppSpacing.md),

                  // ── Info row ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoItem(
                          icon: game.isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
                          text: game.isOnline ? 'Online' : (game.location?.address ?? 'Local'),
                          color: theme.colorScheme.primary,
                        ),
                        _InfoItem(
                          icon: Icons.group_outlined,
                          text: '${game.currentPlayers}/${game.maxPlayers} players',
                          color: game.isFull ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),

                  // ── Action buttons (state-driven) ──────────────────────
                  SizedBox(height: AppSpacing.md),
                  _ActionButtons(
                    context: context,
                    game: game,
                    isCreator: _isCreator,
                    isJoined: _isJoined,
                    onViewDetails: onTap,
                    onJoin: onJoin,
                    onLeave: onLeave,
                    onCancel: onCancel,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
          ),

          // ── Top-right delete icon (creator only) ────────────────
          if (_isCreator && onDelete != null)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'Delete Game',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        size: 22,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── State-driven Action Buttons ────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final BuildContext context;
  final GameEntity game;
  final bool isCreator;
  final bool isJoined;
  final VoidCallback? onViewDetails;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const _ActionButtons({
    required this.context,
    required this.game,
    required this.isCreator,
    required this.isJoined,
    this.onViewDetails,
    this.onJoin,
    this.onLeave,
    this.onCancel,
    this.onDelete,
  });

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameChatRoomPage(
          gameId: game.id,
          gameTitle: game.title,
          gameImageUrl: game.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext _) {
    // ── CANCELLED → no actions ──────────────────────────────────
    if (game.status == GameStatus.CANCELLED) {
      return const SizedBox.shrink();
    }

    // ── ENDED → no actions ────────────────────────────────────
    if (game.status == GameStatus.ENDED) {
      return const SizedBox.shrink();
    }

    // ── OPEN / FULL: joined user (creator or participant) ───────
    if (isJoined) {
      return Column(
        children: [
          // Primary: creator -> Go to Chat, participant -> View Details
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: isCreator ? _goToChat : onViewDetails,
              icon: Icon(
                isCreator
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.visibility_outlined,
                size: 16,
              ),
              label: Text(
                isCreator ? 'Go to Chat' : 'View Details',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Secondary actions
          if (isCreator)
            // Creator: Cancel Game only (delete is the top-right icon)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Game',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            )
          else
            // Participant: Leave button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onLeave,
                icon: const Icon(Icons.exit_to_app_rounded, size: 16),
                label: const Text('Leave Game',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),
        ],
      );
    }

    // ── OPEN: not joined, but full ──────────────────────────────
    if (game.isFull) {
      return Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Game Full',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary)),
        )
      );
    }

    // ── OPEN: not joined, has spots ─────────────────────────────
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onJoin,
        icon: const Icon(Icons.login_rounded, size: 18),
        label: Text(
          'Join Game · ${game.spotsLeft} ${game.spotsLeft == 1 ? 'spot' : 'spots'} left',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────────

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoItem({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  final String sport;
  const _SportIcon({required this.sport});

  IconData get _icon {
    final s = sport.toLowerCase();
    if (s.contains('cricket')) return Icons.sports_cricket;
    if (s.contains('tennis')) return Icons.sports_tennis;
    if (s.contains('volleyball')) return Icons.sports_volleyball;
    if (s.contains('baseball')) return Icons.sports_baseball;
    return Icons.sports_esports;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(_icon, size: 22, color: AppColors.primary),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final isOnline = category == 'ONLINE';
    final bgColor = isOnline 
        ? AppColors.info.withValues(alpha: 0.1) 
        : AppColors.success.withValues(alpha: 0.1);
    final textColor = isOnline ? AppColors.info : AppColors.success;
    final icon = isOnline ? Icons.wifi_rounded : Icons.location_on_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GameStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bgColor, textColor) = switch (status) {
      GameStatus.OPEN     => ('Open',      theme.colorScheme.primary.withValues(alpha: 0.12), theme.colorScheme.primary),
      GameStatus.FULL     => ('Full',      theme.colorScheme.tertiary.withValues(alpha: 0.12), theme.colorScheme.tertiary),
      GameStatus.ENDED    => ('Ended',     theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12), theme.colorScheme.onSurfaceVariant),
      GameStatus.CANCELLED=> ('Cancelled', theme.colorScheme.error.withValues(alpha: 0.12),   theme.colorScheme.error),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.4)),
    );
  }
}

class _GameImagePlaceholder extends StatelessWidget {
  final String sport;
  const _GameImagePlaceholder({required this.sport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              size: 42,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              sport.isEmpty ? 'Game Image' : '$sport Image',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

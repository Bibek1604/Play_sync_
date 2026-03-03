import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/game_entity.dart';
import '../pages/game_chat_page.dart';

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
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      color: AppColors.surface,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (_isJoined) {
                onTap?.call();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Join game first to view game details.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (game.creatorName.isNotEmpty)
                              Row(
                                children: [
                                  Text(
                                    'by ${game.creatorName}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textTertiary),
                                  ),
                                  if (_isCreator) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('YOU', style: TextStyle(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.bold, 
                                        color: AppColors.primary
                                      )),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                      // Leave space for the delete icon when creator
                      if (_isCreator) SizedBox(width: 38),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: AppSpacing.md),

                  // ── Info row ─────────────────────────────────────────
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _InfoItem(
                        icon: game.isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
                        text: game.isOnline ? 'Online' : (game.location?.address ?? 'Local'),
                        color: AppColors.primary,
                      ),
                      _InfoItem(
                        icon: Icons.group_outlined,
                        text: '${game.currentPlayers}/${game.maxPlayers} players',
                        color: game.isFull ? AppColors.error : AppColors.textSecondary,
                      ),
                    ],
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
                        color: AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        size: 22,
                        color: AppColors.error,
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
        builder: (_) => GameChatPage(game: game),
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
                size: 18,
              ),
              label: Text(
                isCreator ? 'Go to Chat' : 'View Details',
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
          ),
          SizedBox(height: AppSpacing.sm),
          // Secondary actions
          if (isCreator)
            // Creator: Cancel Game only (delete is the top-right icon)
            SizedBox(
              width: double.infinity,
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
              height: 36,
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
        ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        SizedBox(width: AppSpacing.xs),
        Text(text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SportIcon extends StatelessWidget {
  final String sport;
  const _SportIcon({required this.sport});

  IconData get _icon {
    final s = sport.toLowerCase();
    if (s.contains('football') || s.contains('soccer')) return Icons.sports_soccer;
    if (s.contains('basketball')) return Icons.sports_basketball;
    if (s.contains('cricket')) return Icons.sports_cricket;
    if (s.contains('tennis')) return Icons.sports_tennis;
    if (s.contains('volleyball')) return Icons.sports_volleyball;
    if (s.contains('baseball')) return Icons.sports_baseball;
    if (s.contains('chess')) return Icons.extension;
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
    final (label, bgColor, textColor) = switch (status) {
      GameStatus.OPEN     => ('Open',      AppColors.primary.withValues(alpha: 0.12), AppColors.primary),
      GameStatus.FULL     => ('Full',      AppColors.warning.withValues(alpha: 0.12), AppColors.warning),
      GameStatus.ENDED    => ('Ended',     AppColors.textTertiary.withValues(alpha: 0.12), AppColors.textSecondary),
      GameStatus.CANCELLED=> ('Cancelled', AppColors.error.withValues(alpha: 0.12),   AppColors.error),
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

import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../domain/entities/game_entity.dart';

/// GameCard — shows game info with state-driven action buttons.
///
/// Button logic (state-driven, never error-driven):
///   • Creator + OPEN  → "Go to Chat" + "Cancel Game"
///   • Participant (not creator) + OPEN → "Go to Chat" + "Leave Game"
///   • Not joined + OPEN + not full → "Join Game"
///   • Not joined + OPEN + full → "Game Full" (disabled)
///   • ENDED   → "View Results"
///   • CANCELLED → badge only, no action
class GameCard extends StatelessWidget {
  final GameEntity game;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const GameCard({
    super.key,
    required this.game,
    this.currentUserId,
    this.onTap,
    this.onJoin,
    this.onLeave,
    this.onDelete,
  });

  bool get _isCreator =>
      currentUserId != null && game.isCreator(currentUserId!);

  bool get _isParticipant =>
      currentUserId != null && game.isParticipant(currentUserId!);

  /// Whether the current user is involved in the game (creator or participant)
  bool get _isJoined => _isCreator || _isParticipant;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
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
                          Text(
                            'by ${game.creatorName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
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
                onJoin: onJoin,
                onLeave: onLeave,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
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
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const _ActionButtons({
    required this.context,
    required this.game,
    required this.isCreator,
    required this.isJoined,
    this.onJoin,
    this.onLeave,
    this.onDelete,
  });

  void _goToChat() {
    Navigator.pushNamed(
      context,
      AppRoutes.gameChat,
      arguments: {'gameId': game.id, 'gameTitle': game.title},
    );
  }

  @override
  Widget build(BuildContext _) {
    // ── CANCELLED → no actions ──────────────────────────────────
    if (game.status == GameStatus.CANCELLED) {
      return const SizedBox.shrink();
    }

    // ── ENDED → View Results ────────────────────────────────────
    if (game.status == GameStatus.ENDED) {
      return const SizedBox.shrink();
    }

    // ── OPEN / FULL: joined user (creator or participant) ───────
    if (isJoined) {
      return Column(
        children: [
          // Primary: Go to Chat
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _goToChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Go to Chat',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
          // Secondary: Cancel (creator) or Leave (participant)
          SizedBox(
            width: double.infinity,
            height: 36,
            child: isCreator
                ? OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel Game',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                  )
                : OutlinedButton.icon(
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
          'Join · ${game.spotsLeft} ${game.spotsLeft == 1 ? 'spot' : 'spots'} left',
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

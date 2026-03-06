import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/providers/camera_dark_mode_provider.dart';
import '../../domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game_chat/game_chat.dart';

/// GameCard — shows game info with state-driven action buttons.
///
/// Button logic (state-driven, never error-driven):
///   • Creator + OPEN  → "Go to Chat" + "Cancel" + "Delete"
///   • Participant (not creator) + OPEN → "View Details" + "Leave Game"
///   • Not joined + OPEN + not full → "Join Game"
///   • Not joined + OPEN + full → "Game Full" (disabled)
///   • ENDED   → "View Results"
///   • CANCELLED → badge only, no action
///
/// [isAlreadyJoined] — override from parent: true when the game appears in
/// myJoinedGames or myCreatedGames even if participant list isn't populated.
class GameCard extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<GameCard> createState() => _GameCardState();
}

class _GameCardState extends ConsumerState<GameCard> {
  bool _isProcessing = false;

  /// Creator check: prefer the reliable server-backed flag, fall back to local field.
  bool get _isCreator =>
      widget.isAlreadyCreator ||
      (widget.currentUserId != null && widget.game.isCreator(widget.currentUserId!));

  bool get _isParticipant =>
      widget.currentUserId != null && widget.game.isParticipant(widget.currentUserId!);

  /// Whether the current user is involved in the game (creator or participant).
  /// Prefers [isAlreadyJoined] override, then falls back to participant list check.
  bool get _isJoined => widget.isAlreadyJoined || _isCreator || _isParticipant;

  /// Check if user can access chat (creator or participant)
  bool get _canAccessChat => _isCreator || _isParticipant || widget.isAlreadyJoined;

  /// Prevent duplicate action calls
  Future<void> _handleAction(Future<void> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use camera dark mode provider for theme detection
    final cameraDarkMode = ref.watch(cameraDarkModeProvider);
    final theme = Theme.of(context);
    final isDark = cameraDarkMode; // Use camera sensor for dark mode
    
    if (widget.currentUserId != null && (widget.game.isCreator(widget.currentUserId!) || widget.isAlreadyCreator)) {
      debugPrint('[GameCard] Detected CREATOR for ${widget.game.title}: currentUserId=${widget.currentUserId}, game.creatorId=${widget.game.creatorId}, isAlreadyCreator=${widget.isAlreadyCreator}');
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: isDark ? 4 : 2,
      shadowColor: isDark ? Colors.black45 : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : theme.dividerColor,
          width: isDark ? 1.5 : 1,
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Stack(
        children: [
          InkWell(
            onTap: _isProcessing ? null : () {
              if (_isJoined) {
                widget.onTap?.call();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Join game first to view details & access chat'),
                      ),
                    ],
                  ),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: widget.game.imageUrl != null && widget.game.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.game.imageUrl!,
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
                                    sport: widget.game.sport,
                                    isDark: isDark,
                                  ),
                                )
                              : _GameImagePlaceholder(sport: widget.game.sport, isDark: isDark),
                        ),
                      ),
                      // Chat access indicator
                      if (_canAccessChat)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Chat Unlocked',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),

                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      _SportIcon(sport: widget.game.sport),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.game.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurface,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'by ${widget.game.creatorName.isNotEmpty ? widget.game.creatorName : 'Unknown'}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
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
                      // Chips wrapped with max width constraint to prevent overflow
                      Expanded(
                        flex: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CategoryChip(category: widget.game.category),
                                const SizedBox(width: 6),
                                _StatusChip(status: widget.game.status),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Description ──────────────────────────────────────
                  if (widget.game.description.isNotEmpty) ...[  
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.game.description,
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
                          icon: widget.game.isOnline ? Icons.wifi_rounded : Icons.location_on_outlined,
                          text: widget.game.isOnline ? 'Online' : (widget.game.location?.address ?? 'Local'),
                          color: theme.colorScheme.primary,
                        ),
                        _InfoItem(
                          icon: Icons.group_outlined,
                          text: '${widget.game.currentPlayers}/${widget.game.maxPlayers} players',
                          color: widget.game.isFull ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),

                  // ── Action buttons (state-driven) ──────────────────────
                  SizedBox(height: AppSpacing.md),
                  _ActionButtons(
                    context: context,
                    game: widget.game,
                    isCreator: _isCreator,
                    isJoined: _isJoined,
                    isProcessing: _isProcessing,
                    onViewDetails: widget.onTap,
                    onJoin: () => _handleAction(() async {
                      if (widget.onJoin != null) widget.onJoin!();
                    }),
                    onLeave: () => _handleAction(() async {
                      if (widget.onLeave != null) widget.onLeave!();
                    }),
                    onCancel: () => _handleAction(() async {
                      if (widget.onCancel != null) widget.onCancel!();
                    }),
                    onDelete: widget.onDelete != null ? () => _handleAction(() async {
                      if (widget.onDelete != null) widget.onDelete!();
                    }) : null,
                  ),
                ],
              ),
            ),
          ),

          // ── Top-right delete icon (creator only) ────────────────
          if (_isCreator && widget.onDelete != null)
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'Delete Game',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _isProcessing ? null : () => _handleAction(() async {
                      widget.onDelete!();
                    }),
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
  final bool isProcessing;
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
    required this.isProcessing,
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
          // Primary: creator -> Go to Chat (Dark Blue), participant -> View Details (Blue)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: (isProcessing || (isCreator ? false : onViewDetails == null)) 
                  ? null 
                  : (isCreator ? _goToChat : onViewDetails),
              icon: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
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
                backgroundColor: isCreator 
                    ? const Color(0xFF1E40AF)  // Dark blue for chat
                    : const Color(0xFF0EA5E9), // Sky blue for view details
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: isCreator 
                    ? const Color(0xFF1E40AF).withOpacity(0.3)
                    : const Color(0xFF0EA5E9).withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Secondary actions
          if (isCreator)
            // Creator: Show both Cancel Game and Delete buttons
            Row(
              children: [
                // Cancel Game button
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing || onCancel == null ? null : onCancel,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626), // Red for cancel
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFFDC2626).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  SizedBox(width: AppSpacing.sm),
                  // Delete button
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : onDelete,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C2D12), // Dark red for delete
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFF7C2D12).withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            // Participant: Leave button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: isProcessing || onLeave == null ? null : onLeave,
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.exit_to_app_rounded, size: 16),
                label: const Text('Leave Game',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Green for leave
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF10B981).withOpacity(0.3),
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
        onPressed: isProcessing || onJoin == null ? null : onJoin,
        icon: isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.login_rounded, size: 18),
        label: Text(
          isProcessing 
              ? 'Joining...' 
              : 'Join Game · ${game.spotsLeft} ${game.spotsLeft == 1 ? 'spot' : 'spots'} left',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981), // Green for join
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF10B981).withOpacity(0.3),
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
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
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
  final bool isDark;
  const _GameImagePlaceholder({required this.sport, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF334155),
                  const Color(0xFF1E293B),
                ]
              : [
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
              color: isDark
                  ? const Color(0xFF64748B)
                  : AppColors.textSecondary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              sport.isEmpty ? 'Game Image' : '$sport Image',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

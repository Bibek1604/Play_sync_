import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game_chat/game_chat.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
// All button heights, border radii, and colours are defined centrally so
// every card in every browse section looks identical.

const _kCardRadius = 16.0;
const _kBtnHeight  = 44.0;
const _kBtnRadius  = 11.0;
const _kBannerH    = 120.0;

const _kClrJoin    = Color(0xFF22C55E); // green  — join game
const _kClrChat    = Color(0xFF1E3A8A); // navy   — go to chat (AppColors.primary)
const _kClrLeave   = Color(0xFFF97316); // orange — leave game
const _kClrCancel  = Color(0xFFEF4444); // red    — cancel game (creator)
const _kClrFull    = Color(0xFF64748B); // grey   — game full (disabled)

/// GameCard — consistent UI for both Online and Offline browse sections.
///
/// Button matrix (every state is the SAME height/radius — no exceptions):
///   Creator + OPEN/FULL  → [Chat]         [Cancel]
///   Participant + OPEN/FULL → [Chat]       [Leave]
///   Not joined + OPEN    → [Join Game ·N spots left]
///   Not joined + FULL    → [Game Full]  (disabled)
///   ENDED / CANCELLED    → no action buttons
class GameCard extends ConsumerStatefulWidget {
  final GameEntity game;
  final String? currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final bool isAlreadyJoined;
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
  bool _busy = false;

  bool get _isCreator =>
      widget.isAlreadyCreator ||
      (widget.currentUserId != null &&
          widget.game.isCreator(widget.currentUserId!));

  bool get _isParticipant =>
      widget.currentUserId != null &&
      widget.game.isParticipant(widget.currentUserId!);

  bool get _isJoined =>
      widget.isAlreadyJoined || _isCreator || _isParticipant;

  Future<void> _do(VoidCallback? fn) async {
    if (_busy || fn == null) return;
    setState(() => _busy = true);
    try {
      fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toChat() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameChatRoomPage(
            gameId: widget.game.id,
            gameTitle: widget.game.title,
            gameImageUrl: widget.game.imageUrl,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 2), // small lift
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius + 4),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──────────────────────────────────────────────────────
          _Banner(
            game: widget.game,
            isCreator: _isCreator,
            isJoined: _isJoined,
            isDark: isDark,
            onDelete: widget.onDelete != null
                ? () => _do(widget.onDelete)
                : null,
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + sport icon row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SportBadge(sport: widget.game.sport, isDark: isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.game.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'by ${widget.game.creatorName.isNotEmpty ? widget.game.creatorName : 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isCreator) ...[
                                const SizedBox(width: 6),
                                _YouBadge(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Description
                if (widget.game.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.game.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 14),

                // Meta Tag Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _MetaTag(
                        icon: widget.game.isOnline
                            ? Icons.wifi_rounded
                            : Icons.location_on_rounded,
                        label: widget.game.isOnline
                            ? 'Online'
                            : (widget.game.location?.address ?? 'Local'),
                        color: const Color(0xFF0284C7),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _MetaTag(
                        icon: Icons.group_rounded,
                        label:
                            '${widget.game.currentPlayers}/${widget.game.maxPlayers}',
                        color: widget.game.isFull
                            ? const Color(0xFFEF4444)
                            : (isDark ? Colors.white54 : AppColors.textSecondary),
                        isDark: isDark,
                      ),
                      if (widget.game.startTime != null) ...[
                        const SizedBox(width: 10),
                        _MetaTag(
                          icon: Icons.schedule_rounded,
                          label: _fmtTime(widget.game.startTime!),
                          color:
                              isDark ? Colors.white38 : AppColors.textTertiary,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Action buttons ─────────────────────────────────────────
                _Buttons(
                  game: widget.game,
                  isCreator: _isCreator,
                  isJoined: _isJoined,
                  busy: _busy,
                  onChat: _toChat,
                  onJoin: () => _do(widget.onJoin),
                  onLeave: () => _do(widget.onLeave),
                  onCancel: () => _do(widget.onCancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// ─── Banner ───────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final GameEntity game;
  final bool isCreator;
  final bool isJoined;
  final bool isDark;
  final VoidCallback? onDelete;

  const _Banner({
    required this.game,
    required this.isCreator,
    required this.isJoined,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusStyle(game.status);
    return SizedBox(
      height: 260, // increased area
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background soft tint / fill
          Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          ),
          
          // Image Container with Gap
          Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (game.imageUrl != null && game.imageUrl!.isNotEmpty) ...[
                    // LAYER 1: Blurred background (Premium depth)
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: CachedNetworkImage(
                        imageUrl: game.imageUrl!,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.black12),
                      ),
                    ),
                    // LAYER 2: Non-zoomed foreground image
                    CachedNetworkImage(
                      imageUrl: game.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => _PlaceholderBg(
                          sport: game.sport, isDark: isDark),
                      errorWidget: (_, __, ___) =>
                          _PlaceholderBg(sport: game.sport, isDark: isDark),
                    ),
                  ] else
                    _PlaceholderBg(sport: game.sport, isDark: isDark),
                  
                  // Scrim 
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x33000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status chip — top left
          Positioned(
            top: 20,
            left: 20,
            child: _Chip(
              label: statusLabel,
              color: statusColor,
            ),
          ),

          // Join indicator — top right (when joined)
          if (isJoined)
            Positioned(
              top: 20,
              right: onDelete != null ? 62 : 20,
              child: const _Chip(
                label: 'Joined',
                color: Color(0xFF10B981),
              ),
            ),

          // Delete button — top right (creator only)
          if (isCreator && onDelete != null)
            Positioned(
              top: 18,
              right: 18,
              child: _IconBtn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                onTap: onDelete!,
              ),
            ),
        ],
      ),
    );
  }

  static (String, Color) _statusStyle(GameStatus s) => switch (s) {
        GameStatus.OPEN      => ('Open',      const Color(0xFF10B981)),
        GameStatus.FULL      => ('Full',      const Color(0xFFF97316)),
        GameStatus.ENDED     => ('Ended',     const Color(0xFF94A3B8)),
        GameStatus.CANCELLED => ('Cancelled', const Color(0xFFEF4444)),
      };
}

class _PlaceholderBg extends StatelessWidget {
  final String sport;
  final bool isDark;
  const _PlaceholderBg({required this.sport, required this.isDark});

  static IconData _icon(String s) {
    final l = s.toLowerCase();
    if (l.contains('cricket')) return Icons.sports_cricket;
    if (l.contains('tennis')) return Icons.sports_tennis;
    if (l.contains('volleyball')) return Icons.sports_volleyball;
    if (l.contains('football')) return Icons.sports_soccer;
    if (l.contains('basketball')) return Icons.sports_basketball;
    if (l.contains('baseball')) return Icons.sports_baseball;
    return Icons.sports_esports;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [
                  const Color(0xFFE0F2FE),
                  const Color(0xFFBAE6FD).withOpacity(0.5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _icon(sport),
          size: 44,
          color: const Color(0xFF0284C7).withOpacity(isDark ? 0.3 : 0.2),
        ),
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────
// ALL buttons: same height (_kBtnHeight), same border-radius (_kBtnRadius),
// same font size (13), same font weight (w800). Colours only differ by semantic.

class _Buttons extends StatelessWidget {
  final GameEntity game;
  final bool isCreator;
  final bool isJoined;
  final bool busy;
  final VoidCallback onChat;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onCancel;

  const _Buttons({
    required this.game,
    required this.isCreator,
    required this.isJoined,
    required this.busy,
    required this.onChat,
    required this.onJoin,
    required this.onLeave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Ended / cancelled — no buttons
    if (game.status == GameStatus.ENDED ||
        game.status == GameStatus.CANCELLED) {
      return const SizedBox.shrink();
    }

    // Joined (creator or participant)
    if (isJoined) {
      return Row(
        children: [
          // Primary: Chat
          Expanded(
            child: _Btn(
              label: 'Chat',
              icon: Icons.chat_bubble_outline_rounded,
              color: _kClrChat,
              busy: busy,
              onTap: onChat,
            ),
          ),
          const SizedBox(width: 8),
          // Secondary: Cancel (creator) or Leave (participant)
          Expanded(
            child: isCreator
                ? _Btn(
                    label: 'Cancel',
                    icon: Icons.cancel_outlined,
                    color: _kClrCancel,
                    busy: busy,
                    onTap: onCancel,
                    outlined: true,
                  )
                : _Btn(
                    label: 'Leave',
                    icon: Icons.exit_to_app_rounded,
                    color: _kClrLeave,
                    busy: busy,
                    onTap: onLeave,
                    outlined: true,
                  ),
          ),
        ],
      );
    }

    // Not joined + full
    if (game.isFull) {
      return _DisabledBtn(label: 'Game Full · No Spots Left');
    }

    // Not joined + open
    return _Btn(
      label: 'Join Game  ·  ${game.spotsLeft} ${game.spotsLeft == 1 ? 'spot' : 'spots'} left',
      icon: Icons.login_rounded,
      color: _kClrJoin,
      busy: busy,
      onTap: onJoin,
      fullWidth: true,
    );
  }
}

/// Solid or outlined button — same geometry always.
class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  final bool outlined;
  final bool fullWidth;

  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
    this.outlined = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: _kBtnHeight,
      width: fullWidth ? double.infinity : null,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: busy ? null : onTap,
              icon: busy
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 15),
              label: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kBtnRadius),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: busy ? null : onTap,
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 15),
              label: Text(
                label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_kBtnRadius),
                ),
              ),
            ),
    );
    return child;
  }
}

class _DisabledBtn extends StatelessWidget {
  final String label;
  const _DisabledBtn({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: _kBtnHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(_kBtnRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kClrFull,
          ),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SportBadge extends StatelessWidget {
  final String sport;
  final bool isDark;
  const _SportBadge({required this.sport, required this.isDark});

  static IconData _icon(String s) {
    final l = s.toLowerCase();
    if (l.contains('cricket')) return Icons.sports_cricket;
    if (l.contains('tennis')) return Icons.sports_tennis;
    if (l.contains('volleyball')) return Icons.sports_volleyball;
    if (l.contains('football')) return Icons.sports_soccer;
    if (l.contains('basketball')) return Icons.sports_basketball;
    if (l.contains('baseball')) return Icons.sports_baseball;
    return Icons.sports_esports;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon(sport), size: 20, color: AppColors.primary),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _MetaTag({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _YouBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: const Text(
        'YOU',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

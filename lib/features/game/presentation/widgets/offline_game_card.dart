import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/presentation/providers/offline_game_provider.dart';

/// Professional Offline Game Card
///
/// • All role-based button logic is READ from [offlineGameCardStateProvider].
/// • UI owns zero business logic — it only reacts to provider state.
/// • Expand / collapse description animation is handled locally.
class OfflineGameCard extends ConsumerStatefulWidget {
  const OfflineGameCard({
    super.key,
    required this.game,
    required this.onJoin,
    required this.onChat,
    this.onDelete,
  });

  final Game game;
  final VoidCallback onJoin;
  final VoidCallback onChat;
  final VoidCallback? onDelete;

  @override
  ConsumerState<OfflineGameCard> createState() => _OfflineGameCardState();
}

class _OfflineGameCardState extends ConsumerState<OfflineGameCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cardState =
        ref.watch(offlineGameCardStateProvider(widget.game));
    final game = cardState.game;
    final statusColor = cardState.statusColor; // already a Color

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Optional image banner ─────────────────────────────────────
            if (game.imageUrl != null && game.imageUrl!.isNotEmpty)
              _ImageBanner(imageUrl: game.imageUrl!),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ───────────────────────────────────────────
                  _HeaderRow(
                    game: game,
                    statusLabel: cardState.statusLabel,
                    statusColor: statusColor,
                  ),

                  const SizedBox(height: 12),

                  // ── Info row (location · date/time) ───────────────────────
                  _InfoRow(game: game),

                  const SizedBox(height: 12),

                  // ── Player count bar ─────────────────────────────────────
                  _PlayerCountBar(game: game),

                  // ── Description (collapsible) ─────────────────────────────
                  if (game.description != null &&
                      game.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _DescriptionSection(
                      description: game.description!,
                      expanded: _expanded,
                      fadeAnim: _fadeAnim,
                      onToggle: _toggleExpand,
                    ),
                  ],

                  // ── Tags ─────────────────────────────────────────────────
                  if (game.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _TagsRow(tags: game.tags),
                  ],

                  const SizedBox(height: 16),

                  // ── Action button ─────────────────────────────────────────
                  _ActionButton(
                    cardState: cardState,
                    onJoin: widget.onJoin,
                    onChat: widget.onChat,                    onDelete: widget.onDelete,                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets (private, no external dependencies)
// ============================================================================

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.emerald600, AppColors.teal500],
            ),
          ),
          child: const Icon(Icons.location_on_outlined,
              color: Colors.white, size: 48),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 160,
            color: AppColors.slate100,
            child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.game,
    required this.statusLabel,
    required this.statusColor,
  });

  final Game game;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.emerald500.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.sports_esports_outlined,
              color: AppColors.emerald600, size: 24),
        ),
        const SizedBox(width: 12),

        // Title + category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Offline · Local',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Status chip
        _StatusChip(label: statusLabel, color: statusColor),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(game.startTime);
    final timeStr = _formatTime(game.startTime);

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        if (game.location != null && game.location!.isNotEmpty)
          _InfoChip(
            icon: Icons.location_on_outlined,
            label: game.location!,
            color: AppColors.emerald600,
          ),
        _InfoChip(
          icon: Icons.calendar_today_outlined,
          label: dateStr,
          color: AppColors.slate500,
        ),
        _InfoChip(
          icon: Icons.access_time_outlined,
          label: timeStr,
          color: AppColors.slate500,
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlayerCountBar extends StatelessWidget {
  const _PlayerCountBar({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final ratio =
        game.maxPlayers > 0 ? game.currentPlayers / game.maxPlayers : 0.0;
    final barColor = ratio >= 1.0
        ? AppColors.warning
        : ratio >= 0.75
            ? AppColors.warning.withOpacity(0.7)
            : AppColors.emerald500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_outlined,
                size: 15, color: AppColors.slate500),
            const SizedBox(width: 6),
            Text(
              '${game.currentPlayers} / ${game.maxPlayers} Players',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${game.availableSlots} slot${game.availableSlots == 1 ? '' : 's'} left',
              style: TextStyle(
                fontSize: 11,
                color: game.isFull ? AppColors.warning : AppColors.slate400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.slate200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.expanded,
    required this.fadeAnim,
    required this.onToggle,
  });

  final String description;
  final bool expanded;
  final Animation<double> fadeAnim;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
          secondChild: Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
        ),
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              expanded ? 'Show less' : 'Read more',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.emerald600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags});
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.take(4).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.emerald500.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.emerald500.withOpacity(0.25), width: 1),
          ),
          child: Text(
            '#$tag',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.emerald700,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.cardState,
    required this.onJoin,
    required this.onChat,
    this.onDelete,
  });

  final OfflineGameCardState cardState;
  final VoidCallback onJoin;
  final VoidCallback onChat;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    switch (cardState.action) {
      case OfflineCardAction.join:
        return _buildJoinButton();
      case OfflineCardAction.chat:
        return _buildChatButton();
      case OfflineCardAction.delete:
        return _buildDeleteRow();
      case OfflineCardAction.disabled:
        return _buildFullButton();
    }
  }

  Widget _buildJoinButton() {
    if (cardState.isJoining) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald500,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onJoin,
        icon: const Icon(Icons.login_outlined, size: 18),
        label: const Text(
          'Join Game',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald500,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onChat,
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text(
          'Open Chat',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDeleteRow() {
    return Row(
      children: [
        // Chat button (creator can still open chat)
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text(
                'Chat',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal600,
                side: const BorderSide(color: AppColors.teal600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Delete button
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: null, // disabled
        icon: const Icon(Icons.block_outlined, size: 18),
        label: const Text(
          'Game Full',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.slate200,
          foregroundColor: AppColors.slate500,
          disabledBackgroundColor: AppColors.slate200,
          disabledForegroundColor: AppColors.slate500,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

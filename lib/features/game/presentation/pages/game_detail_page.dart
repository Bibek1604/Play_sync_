import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';
import 'package:play_sync_new/features/game/domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_notifier.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';

/// Detailed view of a single game with join/leave/cancel actions.
class GameDetailPage extends ConsumerStatefulWidget {
  final String gameId;
  final GameEntity? preloadedGame;

  const GameDetailPage({super.key, required this.gameId, this.preloadedGame});

  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  GameEntity? _game;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  /// Current user ID from auth state
  String? get _currentUserId {
    try {
      final authState = ref.read(authNotifierProvider);
      return authState.user?.userId;
    } catch (_) {
      return null;
    }
  }

  /// Whether the current user is the creator of this game
  bool get _isCreator => _currentUserId != null && _game?.isCreator(_currentUserId!) == true;

  /// Whether the current user is an active participant (not creator)
  bool get _isParticipant => _currentUserId != null && 
      _game?.isParticipant(_currentUserId!) == true && 
      !_isCreator;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedGame != null) {
      _game = widget.preloadedGame;
      _loading = false;
    }
    _fetchGame();
  }

  Future<void> _fetchGame() async {
    setState(() {
      _loading = _game == null;
      _error = null;
    });
    try {
      final game = await ref.read(gameProvider.notifier).fetchGameById(widget.gameId);
      if (mounted) {
        setState(() {
          _game = game;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _joinGame() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(gameProvider.notifier).joinGame(widget.gameId);
      await _fetchGame();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined game!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _leaveGame() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(gameProvider.notifier).leaveGame(widget.gameId);
      await _fetchGame();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left game'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancelGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Game'),
        content: const Text('Are you sure you want to cancel this game? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(gameProvider.notifier).cancelGame(widget.gameId);
      await _fetchGame();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game cancelled'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_game?.title ?? 'Game Details'),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _game == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchGame, child: const Text('Retry')),
                    ],
                  ),
                )
              : _game == null
                  ? const Center(child: Text('Game not found'))
                  : RefreshIndicator(
                      onRefresh: _fetchGame,
                      child: _GameContent(
                        game: _game!,
                        isDark: isDark,
                        actionLoading: _actionLoading,
                        isCreator: _isCreator,
                        isParticipant: _isParticipant,
                        onJoin: _joinGame,
                        onLeave: _leaveGame,
                        onCancel: _cancelGame,
                      ),
                    ),
    );
  }
}

class _GameContent extends StatelessWidget {
  final GameEntity game;
  final bool isDark;
  final bool actionLoading;
  final bool isCreator;
  final bool isParticipant;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onCancel;

  const _GameContent({
    required this.game,
    required this.isDark,
    required this.actionLoading,
    required this.isCreator,
    required this.isParticipant,
    required this.onJoin,
    required this.onLeave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final activeParticipants = game.participants.where((p) => p.status == ParticipantStatus.ACTIVE).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SportIcon(sport: game.sport),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      game.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatusChip(status: game.status),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game.category,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      game.sport,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (game.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  game.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Info cards
        _InfoRow(icon: Icons.person, label: 'Created by', value: game.creatorName, isDark: isDark),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.people,
          label: 'Players',
          value: '${game.currentPlayers} / ${game.maxPlayers} (${game.spotsLeft} spots left)',
          isDark: isDark,
        ),
        if (game.startTime != null) ...[
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.schedule, label: 'Start', value: dateFormat.format(game.startTime!), isDark: isDark),
        ],
        if (game.endTime != null) ...[
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.schedule, label: 'End', value: dateFormat.format(game.endTime!), isDark: isDark),
        ],
        if (game.location != null && game.location!.address != null) ...[
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.location_on, label: 'Location', value: game.location!.address!, isDark: isDark),
        ],

        // Tags
        if (game.tags.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.secondary : AppColors.primaryDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: game.tags.map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList(),
          ),
        ],

        // Participants
        const SizedBox(height: 24),
        Text(
          'Participants (${activeParticipants.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.secondary : AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        if (activeParticipants.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('No participants yet', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
            ),
          )
        else
          ...activeParticipants.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: p.avatar != null ? NetworkImage(p.avatar!) : null,
                  child: p.avatar == null
                      ? Text(
                          p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.displayName.isNotEmpty ? p.displayName : 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.secondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(p.joinedAt),
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                ),
              ],
            ),
          )),

        const SizedBox(height: 30),

        // Action buttons - role-based
        if (actionLoading)
          const Center(child: CircularProgressIndicator())
        else if (game.isOpen) ...[
          // Creator: Cancel Game button only
          if (isCreator) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Game', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
          // Participant (not creator): Leave Game button
          else if (isParticipant) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onLeave,
                icon: const Icon(Icons.exit_to_app_rounded),
                label: const Text('Leave Game', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
          // Others: Join button (if not full)
          else if (!game.isFull) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onJoin,
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  'Join Game · ${game.spotsLeft} ${game.spotsLeft == 1 ? 'spot' : 'spots'} left',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]
          // Game is full, user is not participant
          else ...[
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text(
                  'Game Full',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ]
        // Game not open (ended/cancelled)
        else if (game.isEnded || game.isCancelled) ...[
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                game.isEnded ? 'Game Ended' : 'Game Cancelled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: game.isEnded ? Colors.grey : Colors.red.shade300,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 30),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.secondary : AppColors.textPrimary),
              textAlign: TextAlign.end,
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
    Color color;
    switch (status) {
      case GameStatus.OPEN:
        color = Colors.green;
        break;
      case GameStatus.FULL:
        color = Colors.orange;
        break;
      case GameStatus.ENDED:
        color = Colors.grey;
        break;
      case GameStatus.CANCELLED:
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  final String sport;
  const _SportIcon({required this.sport});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (sport.toLowerCase()) {
      case 'football':
      case 'soccer':
        icon = Icons.sports_soccer;
        break;
      case 'basketball':
        icon = Icons.sports_basketball;
        break;
      case 'cricket':
        icon = Icons.sports_cricket;
        break;
      case 'tennis':
        icon = Icons.sports_tennis;
        break;
      case 'volleyball':
        icon = Icons.sports_volleyball;
        break;
      default:
        icon = Icons.sports;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';
import 'package:play_sync_new/features/game/domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_notifier.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'game_chat_page.dart';

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

  /// Navigate to chat and refresh game state when returning
  void _goToChat() async {
    if (_game == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameChatPage(game: _game!),
      ),
    );
    // Refresh game state when returning from chat to prevent stale data
    if (mounted) {
      _fetchGame();
    }
  }

  @override
  void initState() {
    super.initState();
    // Always fetch fresh data on mount to prevent stale state
    // Ignores preloadedGame to ensure participants list is current
    _fetchGame();
  }

  Future<void> _fetchGame() async {
    setState(() {
      _loading = _game == null;
      _error = null;
    });
    try {
      // Force refresh on GameDetails to ensure always-fresh data
      final game = await ref.read(gameProvider.notifier).fetchGameById(
        widget.gameId,
        forceRefresh: true, // Always bypass cache for GameDetails
      );
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
      // Join game and get fresh updated game with participants
      final updatedGame = await ref.read(gameProvider.notifier).joinGame(widget.gameId);
      
      if (updatedGame != null && mounted) {
        // Update local state with fresh game data
        setState(() {
          _game = updatedGame;
          _actionLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined game!'), backgroundColor: AppColors.success),
        );
      } else if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join game'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _leaveGame() async {
    setState(() => _actionLoading = true);
    try {
      // Leave game and get fresh updated game with participants
      final updatedGame = await ref.read(gameProvider.notifier).leaveGame(widget.gameId);
      
      if (updatedGame != null && mounted) {
        // Update local state with fresh game data
        setState(() {
          _game = updatedGame;
          _actionLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left game'), backgroundColor: AppColors.warning),
        );
      } else if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave game'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e'), backgroundColor: AppColors.error),
        );
      }
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
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      // Cancel game and get updated game entity
      final updatedGame = await ref.read(gameProvider.notifier).cancelGame(widget.gameId);
      
      if (updatedGame != null && mounted) {
        // Update local state with fresh game data
        setState(() {
          _game = updatedGame;
          _actionLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game cancelled'), backgroundColor: AppColors.error),
        );
      } else if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel game'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game'),
        content: const Text('Are you sure you want to permanently delete this game? All chat messages will also be deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      final success = await ref.read(gameProvider.notifier).deleteGame(widget.gameId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game deleted'), backgroundColor: AppColors.success),
          );
          Navigator.of(context).pop(); // Go back after deletion
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(gameProvider).error ?? 'Failed to delete game'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_game?.title ?? 'Game Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _game == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
                        onDelete: _deleteGame,
                        onGoToChat: _goToChat,
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
  final VoidCallback onDelete;
  final VoidCallback onGoToChat;

  const _GameContent({
    required this.game,
    required this.isDark,
    required this.actionLoading,
    required this.isCreator,
    required this.isParticipant,
    required this.onJoin,
    required this.onLeave,
    required this.onCancel,
    required this.onDelete,
    required this.onGoToChat,
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
              color: isDark ? AppColors.cardDark : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
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
          // Go to Chat button for participants and creators
          if (isCreator || isParticipant) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onGoToChat,
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('Go to Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Creator: Cancel + Delete buttons
          if (isCreator) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Game', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Game', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
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
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning, width: 1.5),
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
                color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'Game Full',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTertiary,
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
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                game.isEnded ? 'Game Ended' : 'Game Cancelled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: game.isEnded ? AppColors.textTertiary : AppColors.error,
                ),
              ),
            ),
          ),
          // Creator can still delete ended/cancelled games
          if (isCreator) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Game', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
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
        color: isDark ? AppColors.cardDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
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
        color = AppColors.success;
        break;
      case GameStatus.FULL:
        color = AppColors.warning;
        break;
      case GameStatus.ENDED:
        color = AppColors.textTertiary;
        break;
      case GameStatus.CANCELLED:
        color = AppColors.error;
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

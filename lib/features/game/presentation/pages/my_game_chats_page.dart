import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import 'package:play_sync_new/features/game_chat/game_chat.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';

const _sportIcons = <String, IconData>{
  'Football': Icons.sports_soccer,
  'Basketball': Icons.sports_basketball,
  'Cricket': Icons.sports_cricket,
  'Chess': Icons.casino_outlined,
  'Tennis': Icons.sports_tennis,
  'Badminton': Icons.sports_tennis,
  'Other': Icons.sports,
  'All': Icons.sports,
};

class MyGameChatsPage extends ConsumerStatefulWidget {
  const MyGameChatsPage({super.key});

  @override
  ConsumerState<MyGameChatsPage> createState() => _MyGameChatsPageState();
}

class _MyGameChatsPageState extends ConsumerState<MyGameChatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(gameProvider.notifier);
      notifier.fetchMyCreatedGames();
      notifier.fetchMyJoinedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.userId;

    // Merge created + joined, deduplicate by id
    // Only include active games (OPEN / FULL) — not ENDED or CANCELLED
    final seen = <String>{};
    final myGames = <GameEntity>[];
    for (final g in [...gameState.myCreatedGames, ...gameState.myJoinedGames]) {
      if (!seen.add(g.id)) continue;
      if (g.status == GameStatus.ENDED || g.status == GameStatus.CANCELLED) continue;
      myGames.add(g);
    }

    // Sort: open first, then by most recently updated
    myGames.sort((a, b) {
      if (a.isOpen && !b.isOpen) return -1;
      if (!a.isOpen && b.isOpen) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    final isLoading = gameState.isLoading && myGames.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Game Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final notifier = ref.read(gameProvider.notifier);
              notifier.fetchMyCreatedGames();
              notifier.fetchMyJoinedGames();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myGames.isEmpty
              ? _EmptyState(
                  onBrowse: () {
                    Navigator.of(context).pushNamed(AppRoutes.game);
                  },
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final notifier = ref.read(gameProvider.notifier);
                    await Future.wait([
                      notifier.fetchMyCreatedGames(),
                      notifier.fetchMyJoinedGames(),
                    ]);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: myGames.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final game = myGames[index];
                      final isCreator = userId != null && game.isCreator(userId);
                      return _GameChatTile(
                        game: game,
                        isCreator: isCreator,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameChatRoomPage(
                              gameId: game.id,
                              gameTitle: game.title,
                              gameImageUrl: game.imageUrl,
                            ),
                          ),
                        ),
                        onLeave: isCreator
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Leave Game'),
                                    content: const Text(
                                        'Are you sure you want to leave this game?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.warning),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Leave'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  final result = await ref
                                      .read(gameProvider.notifier)
                                      .leaveGame(game.id);
                                  if (result != null) {
                                    ref
                                        .read(chatProvider.notifier)
                                        .leaveRoom(game.id);
                                  }
                                }
                              },
                        onDelete: isCreator
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancel Game'),
                                    content: const Text(
                                        'Are you sure you want to cancel this game?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Cancel Game'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  ref
                                      .read(gameProvider.notifier)
                                      .cancelGame(game.id);
                                }
                              }
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────

class _GameChatTile extends StatelessWidget {
  const _GameChatTile({
    required this.game,
    required this.isCreator,
    required this.onTap,
    this.onLeave,
    this.onDelete,
  });

  final GameEntity game;
  final bool isCreator;
  final VoidCallback onTap;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final sportIcon = _sportIcons[game.sport] ?? Icons.sports;
    final statusColor = _statusColor(game.status);
    final statusLabel = _statusLabel(game.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      color: AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Sport icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(sportIcon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),

              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Creator badge
                        if (isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Player count
                        Icon(Icons.group_outlined,
                            size: 13,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${game.currentPlayers}/${game.maxPlayers}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat arrow / delete
              const SizedBox(width: 4),
              if (isCreator && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 22),
                  tooltip: 'Cancel Game',
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else if (!isCreator && onLeave != null)
                IconButton(
                  icon: const Icon(Icons.exit_to_app_rounded,
                      color: AppColors.warning, size: 22),
                  tooltip: 'Leave Game',
                  onPressed: onLeave,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(GameStatus status) => switch (status) {
        GameStatus.OPEN => const Color(0xFF059669),
        GameStatus.FULL => const Color(0xFFD97706),
        GameStatus.ENDED => const Color(0xFF6B7280),
        GameStatus.CANCELLED => const Color(0xFFDC2626),
      };

  String _statusLabel(GameStatus status) => switch (status) {
        GameStatus.OPEN => 'Open',
        GameStatus.FULL => 'Full',
        GameStatus.ENDED => 'Ended',
        GameStatus.CANCELLED => 'Cancelled',
      };
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            const Text(
              'No game chats yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Join or create a game to start chatting\nwith other players.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.sports_esports_rounded),
              label: const Text('Browse Games'),
            ),
          ],
        ),
      ),
    );
  }
}

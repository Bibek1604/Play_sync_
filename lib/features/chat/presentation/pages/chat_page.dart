import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_notifier.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_room_page.dart';
import '../../../game/presentation/providers/game_notifier.dart';
import '../../../game/domain/entities/game_entity.dart';
import '../../../game/presentation/pages/game_chat_page.dart';
import '../../../../core/widgets/app_drawer.dart';

/// Chat rooms list page — shows joined game chats + regular DMs/group rooms.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    // Load joined games so their chats appear automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(chatProvider.notifier).fetchRooms(),
      ref.read(gameProvider.notifier).fetchMyJoinedGames(),
      ref.read(gameProvider.notifier).fetchMyCreatedGames(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final gameState = ref.watch(gameProvider);
    final cs = Theme.of(context).colorScheme;

    // Combine joined + created games, deduplicated by id.
    // Filter to only show OPEN or FULL games (active games only)
    final seen = <String>{};
    final gameChats = [
      ...gameState.myJoinedGames,
      ...gameState.myCreatedGames,
    ].where((g) => 
      seen.add(g.id) && 
      (g.status == GameStatus.OPEN || g.status == GameStatus.FULL)
    ).toList();

    final hasGameChats = gameChats.isNotEmpty;
    final hasRooms = chatState.rooms.isNotEmpty;
    final isLoading = chatState.isLoadingRooms;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'New message',
            onPressed: () {},
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (!hasGameChats && !hasRooms)
              ? _EmptyState(onRefresh: _refresh)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    slivers: [
                      // ── Game Chats section ────────────────────────────
                      if (hasGameChats) ...[
                        _SectionHeader(
                          icon: Icons.sports_esports_rounded,
                          label: 'Game Chats',
                          color: cs.primary,
                        ),
                        SliverList.separated(
                          itemCount: gameChats.length,
                          separatorBuilder: (_, _) => Divider(
                              height: 1, indent: 72, color: cs.outlineVariant),
                          itemBuilder: (_, i) {
                            final game = gameChats[i];
                            return _GameChatTile(
                              game: game,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameChatPage(game: game),
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      // ── Regular rooms section ─────────────────────────
                      if (hasRooms) ...[
                        _SectionHeader(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Messages',
                          color: cs.secondary,
                        ),
                        SliverList.separated(
                          itemCount: chatState.rooms.length,
                          separatorBuilder: (_, _) => Divider(
                              height: 1, indent: 72, color: cs.outlineVariant),
                          itemBuilder: (_, i) {
                            final room = chatState.rooms[i];
                            return _RoomTile(
                              room: room,
                              onTap: () {
                                ref
                                    .read(chatProvider.notifier)
                                    .openRoom(room.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatRoomPage(roomId: room.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: cs.outline.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No conversations yet',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('Join a game to start chatting',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Game Chat Tile ───────────────────────────────────────────────────────────

class _GameChatTile extends StatelessWidget {
  final GameEntity game;
  final VoidCallback onTap;
  const _GameChatTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final statusColor = switch (game.status) {
      GameStatus.OPEN => const Color(0xFF10B981),
      GameStatus.FULL => const Color(0xFFF97316),
      GameStatus.ENDED => cs.outline,
      GameStatus.CANCELLED => const Color(0xFFEF4444),
    };

    final subtitle = '${game.currentPlayers}/${game.maxPlayers} players'
        '${game.sport.isNotEmpty ? ' · ${game.sport}' : ''}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                (game.image != null && game.image!.isNotEmpty)
                    ? NetworkImage(game.image!)
                    : null,
            backgroundColor: cs.primaryContainer,
            child: (game.image == null || game.image!.isEmpty)
                ? Icon(Icons.sports_esports_rounded,
                    color: cs.onPrimaryContainer)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                    color: cs.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        game.title,
        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              game.status.name,
              style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: cs.outline),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  const _RoomTile({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                room.avatarUrl != null ? NetworkImage(room.avatarUrl!) : null,
            backgroundColor: cs.primaryContainer,
            child: room.avatarUrl == null
                ? Icon(
                    room.isGroupChat ? Icons.group : Icons.person,
                    color: cs.onPrimaryContainer,
                  )
                : null,
          ),
          if (room.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${room.unreadCount > 99 ? "99+" : room.unreadCount}',
                  style: TextStyle(
                      fontSize: 10,
                      color: cs.onError,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      title: Text(room.name,
          style: tt.bodyLarge?.copyWith(
              fontWeight: room.unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
      subtitle: room.lastMessage != null
          ? Text(room.lastMessage!,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1)
          : null,
      trailing: room.lastMessageAt != null
          ? Text(
              _timeAgo(room.lastMessageAt!),
              style: tt.labelSmall?.copyWith(
                  color: room.unreadCount > 0 ? cs.primary : cs.outline),
            )
          : null,
      onTap: onTap,
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

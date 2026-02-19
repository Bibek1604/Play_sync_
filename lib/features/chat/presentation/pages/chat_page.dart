import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_notifier.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_room_page.dart';

/// Chat rooms list page.
class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'New message',
            onPressed: () {},
          ),
        ],
      ),
      body: state.isLoadingRooms
          ? const Center(child: CircularProgressIndicator())
          : state.rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: cs.outline.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('No conversations yet',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => ref.read(chatProvider.notifier).fetchRooms(),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(chatProvider.notifier).fetchRooms(),
                  child: ListView.separated(
                    itemCount: state.rooms.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 72, color: cs.outlineVariant),
                    itemBuilder: (_, i) {
                      final room = state.rooms[i];
                      return _RoomTile(
                        room: room,
                        onTap: () {
                          ref.read(chatProvider.notifier).openRoom(room.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatRoomPage(roomId: room.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
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

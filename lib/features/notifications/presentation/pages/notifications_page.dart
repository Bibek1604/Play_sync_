import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/notifications_notifier.dart';
import '../../domain/entities/notification_entity.dart';

/// Shows all in-app notifications with read/unread states.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: TextStyle(
                      color: cs.onError,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(notificationsProvider.notifier)
                .fetchNotifications(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(notificationsProvider.notifier)
                  .fetchNotifications(),
              child: state.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('No notifications yet',
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) => _NotificationTile(
                        notification: state.notifications[i],
                        onTap: () => ref
                            .read(notificationsProvider.notifier)
                            .markRead(state.notifications[i].id),
                      ),
                    ),
            ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  static final _timeFmt = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      tileColor: notification.isRead
          ? null
          : cs.primary.withValues(alpha: 0.06),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primaryContainer,
        ),
        child: Center(
          child: Text(notification.iconEmoji,
              style: const TextStyle(fontSize: 20)),
        ),
      ),
      title: Text(
        notification.message,
        style: TextStyle(
          fontWeight:
              notification.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _timeFmt.format(notification.createdAt),
        style: TextStyle(
            fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary,
              ),
            ),
      onTap: onTap,
    );
  }
}

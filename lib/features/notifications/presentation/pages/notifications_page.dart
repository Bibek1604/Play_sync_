import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/notifications_notifier.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/app_drawer.dart';

/// Shows all in-app notifications with read/unread states.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                      color: Colors.white,
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
              child: Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            onPressed: () => ref
                .read(notificationsProvider.notifier)
                .fetchNotifications(),
          ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.error != null && state.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => ref
                            .read(notificationsProvider.notifier)
                            .fetchNotifications(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref
                      .read(notificationsProvider.notifier)
                      .fetchNotifications(),
                  child: state.notifications.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3),
                            Icon(Icons.notifications_none,
                                size: 64,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No notifications yet',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: state.notifications.length +
                              (state.hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == state.notifications.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: state.isLoading
                                      ? CircularProgressIndicator(
                                          color: AppColors.primary)
                                      : TextButton(
                                          onPressed: () => ref
                                              .read(notificationsProvider
                                                  .notifier)
                                              .loadMore(),
                                          child: Text(
                                            'Load more',
                                            style: TextStyle(
                                                color: AppColors.primary),
                                          ),
                                        ),
                                ),
                              );
                            }
                            return _NotificationTile(
                              notification: state.notifications[i],
                              isDark: isDark,
                              onTap: () {
                                final n = state.notifications[i];
                                if (!n.read) {
                                  ref
                                      .read(notificationsProvider.notifier)
                                      .markRead(n.id);
                                }
                                // Navigate to related game if applicable
                                if (n.gameId != null) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.gameDetail,
                                    arguments: {'gameId': n.gameId},
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback onTap;

  static final _timeFmt = DateFormat('MMM d, h:mm a');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: notification.read
            ? (isDark ? AppColors.cardDark : Colors.white)
            : (isDark
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.primaryLight.withValues(alpha: 0.15)),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primaryLight.withValues(alpha: 0.3),
          ),
          child: Center(
            child: Text(notification.iconEmoji,
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.read ? FontWeight.normal : FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.message.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _timeFmt.format(notification.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

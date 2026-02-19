import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/notification.dart';
import '../providers/notification_state_provider.dart';

/// Notifications Page
///
/// Displays real notifications fetched from the backend for the current player.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor:
          isDark ? AppColors.backgroundPrimaryDark : AppColors.backgroundSecondaryLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundSecondaryDark : Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emerald500, AppColors.teal500],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            if (notifState.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifState.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifState.unreadCount > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded, color: AppColors.emerald500),
              onPressed: () async {
                await ref.read(notificationProvider.notifier).markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('All notifications marked as read'),
                      backgroundColor: AppColors.emerald500,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.emerald500,
        onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
        child: _buildBody(context, isDark, notifState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
              const SizedBox(height: 16),
              Text(
                'Failed to load notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(notificationProvider.notifier).loadNotifications(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 80,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 80,
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
      itemBuilder: (context, index) {
        final n = state.notifications[index];
        return _NotificationTile(
          notification: n,
          isDark: isDark,
          onTap: () {
            if (!n.read) {
              ref.read(notificationProvider.notifier).markAsRead(n.id);
            }
          },
        );
      },
    );
  }
}

// ─── helpers ────────────────────────────────────────────────────────────────

({IconData icon, Color color}) _iconForType(NotificationType type) {
  switch (type) {
    case NotificationType.gameJoin:
      return (icon: Icons.login_rounded, color: AppColors.emerald500);
    case NotificationType.gameLeave:
      return (icon: Icons.logout_rounded, color: AppColors.textSecondaryLight);
    case NotificationType.gameCreate:
      return (icon: Icons.add_circle_rounded, color: AppColors.teal600);
    case NotificationType.gameFull:
      return (icon: Icons.group_rounded, color: AppColors.warning);
    case NotificationType.gameStart:
      return (icon: Icons.play_circle_rounded, color: AppColors.emerald500);
    case NotificationType.gameEnd:
    case NotificationType.gameCompleted:
      return (icon: Icons.check_circle_rounded, color: AppColors.success);
    case NotificationType.chatMessage:
      return (icon: Icons.chat_bubble_rounded, color: AppColors.info);
    case NotificationType.leaderboard:
      return (icon: Icons.leaderboard_rounded, color: AppColors.purple500);
    case NotificationType.gameCancelled:
    case NotificationType.gameCancel:
      return (icon: Icons.cancel_rounded, color: AppColors.error);
    case NotificationType.completionBonus:
      return (icon: Icons.stars_rounded, color: AppColors.warning);
    case NotificationType.system:
      return (icon: Icons.info_rounded, color: AppColors.info);
  }
}

// ─── Notification Tile ───────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final Notification notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (:icon, :color) = _iconForType(notification.type);
    final isUnread = !notification.read;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? (isDark
                ? AppColors.emerald500.withValues(alpha: 0.06)
                : AppColors.emerald500.withValues(alpha: 0.04))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.emerald500,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


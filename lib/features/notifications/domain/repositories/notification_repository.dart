import 'package:play_sync_new/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
  /// Get notifications with pagination
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unread,
  });

  /// Get unread count
  Future<int> getUnreadCount();

  /// Mark all as read
  Future<void> markAllAsRead();

  /// Mark specific notification as read
  Future<void> markAsRead(String id);

  /// Watch for new notifications (real-time)
  Stream<Notification> watchNotifications();
}

class NotificationListResult {
  final List<Notification> notifications;
  final int unreadCount;
  final int page;
  final int total;
  final int totalPages;

  NotificationListResult({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.total,
    required this.totalPages,
  });
}

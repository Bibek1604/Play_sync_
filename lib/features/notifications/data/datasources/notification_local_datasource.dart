import 'package:hive/hive.dart';
import 'package:play_sync_new/features/notifications/data/models/notification_dto.dart';

/// Local data source for notifications using Hive
/// Implements hybrid strategy: cache recent notifications + merge with real-time updates
class NotificationLocalDataSource {
  final Box<dynamic> _metadataBox;
  
  static const String _notificationsKey = 'notifications';
  static const String _unreadCountKey = 'unread_count';
  static const int _maxCachedNotifications = 50; // Cache last 50 notifications

  NotificationLocalDataSource(this._metadataBox);

  /// Cache notifications list (stores as JSON for flexibility with real-time updates)
  Future<void> cacheNotifications(List<NotificationDto> notifications) async {
    final notificationsJson = notifications
        .take(_maxCachedNotifications)
        .map((e) => e.toJson())
        .toList();
    
    await _metadataBox.put(_notificationsKey, notificationsJson);
  }

  /// Get cached notifications
  List<NotificationDto>? getCachedNotifications() {
    final cached = _metadataBox.get(_notificationsKey);
    if (cached == null) return null;

    try {
      final List<dynamic> notificationsList = cached as List<dynamic>;
      return notificationsList
          .map((json) => NotificationDto.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Add new notification (from real-time update) and merge with cache
  Future<void> addNotification(NotificationDto notification) async {
    final cached = getCachedNotifications() ?? [];
    
    // Add new notification at the beginning
    cached.insert(0, notification);
    
    // Keep only last N notifications
    final trimmed = cached.take(_maxCachedNotifications).toList();
    
    await cacheNotifications(trimmed);
  }

  /// Mark notification as read in cache
  Future<void> markAsReadInCache(String notificationId) async {
    final cached = getCachedNotifications();
    if (cached == null) return;

    final updated = cached.map((notification) {
      if (notification.id == notificationId) {
        return NotificationDto(
          id: notification.id,
          user: notification.user,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          data: notification.data,
          link: notification.link,
          read: true,
          createdAt: notification.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      return notification;
    }).toList();

    await cacheNotifications(updated);
  }

  /// Cache unread count
  Future<void> cacheUnreadCount(int count) async {
    await _metadataBox.put(_unreadCountKey, count);
  }

  /// Get cached unread count
  int? getCachedUnreadCount() {
    return _metadataBox.get(_unreadCountKey) as int?;
  }

  /// Check if has cached notifications
  bool hasCachedNotifications() {
    return _metadataBox.containsKey(_notificationsKey);
  }

  /// Clear all cached notifications
  Future<void> clearCache() async {
    await _metadataBox.delete(_notificationsKey);
    await _metadataBox.delete(_unreadCountKey);
  }

  /// Get cache info for monitoring
  Map<String, dynamic> getCacheInfo() {
    final cached = getCachedNotifications();
    return {
      'has_cache': cached != null,
      'count': cached?.length ?? 0,
      'unread_count': getCachedUnreadCount() ?? 0,
    };
  }
}

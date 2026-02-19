import 'package:play_sync_new/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:play_sync_new/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:play_sync_new/features/notifications/domain/entities/notification.dart';
import 'package:play_sync_new/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationLocalDataSource _localDataSource;

  NotificationRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<NotificationListResult> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unread,
  }) async {
    // Check cache first (for page 1 only)
    if (page == 1) {
      final cached = _localDataSource.getCachedNotifications();
      if (cached != null) {
        // Return cached immediately + refresh in background
        _refreshNotificationsCache(page: page, limit: limit, unread: unread);
        
        final filteredNotifications = unread == true 
            ? cached.where((dto) => !dto.read).toList()
            : cached;
        
        return NotificationListResult(
          notifications: filteredNotifications.map((dto) => dto.toEntity()).toList(),
          unreadCount: _localDataSource.getCachedUnreadCount() ?? 0,
          page: 1,
          total: filteredNotifications.length,
          totalPages: 1,
        );
      }
    }

    // Fetch from remote if no cache or not page 1
    final resultDto = await _remoteDataSource.getNotifications(
      page: page,
      limit: limit,
      unread: unread,
    );

    // Cache the results (page 1 only)
    if (page == 1) {
      await _localDataSource.cacheNotifications(resultDto.notifications);
      await _localDataSource.cacheUnreadCount(resultDto.unreadCount);
    }

    return NotificationListResult(
      notifications: resultDto.notifications.map((dto) => dto.toEntity()).toList(),
      unreadCount: resultDto.unreadCount,
      page: resultDto.pagination.page,
      total: resultDto.pagination.total,
      totalPages: resultDto.pagination.totalPages,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    // Check cache first
    final cached = _localDataSource.getCachedUnreadCount();
    if (cached != null) {
      // Return cached immediately + refresh in background
      _refreshUnreadCountCache();
      return cached;
    }

    // Fetch from remote if no cache
    final count = await _remoteDataSource.getUnreadCount();
    
    // Cache the count
    await _localDataSource.cacheUnreadCount(count);
    
    return count;
  }

  @override
  Future<void> markAllAsRead() async {
    await _remoteDataSource.markAllAsRead();
    
    // Update cache to reflect all read
    await _localDataSource.cacheUnreadCount(0);
  }

  @override
  Future<void> markAsRead(String id) async {
    await _remoteDataSource.markAsRead(id);
    
    // Update cache to mark notification as read
    await _localDataSource.markAsReadInCache(id);
    
    // Decrease unread count
    final currentCount = _localDataSource.getCachedUnreadCount() ?? 0;
    if (currentCount > 0) {
      await _localDataSource.cacheUnreadCount(currentCount - 1);
    }
  }

  @override
  Stream<Notification> watchNotifications() {
    return _remoteDataSource
        .watchNotifications()
        .map((dto) {
          // Add new notification to cache when received via WebSocket
          _localDataSource.addNotification(dto);
          return dto.toEntity();
        });
  }

  /// Background refresh for notifications cache
  Future<void> _refreshNotificationsCache({
    required int page,
    required int limit,
    bool? unread,
  }) async {
    try {
      final result = await _remoteDataSource.getNotifications(
        page: page,
        limit: limit,
        unread: unread,
      );
      await _localDataSource.cacheNotifications(result.notifications);
      await _localDataSource.cacheUnreadCount(result.unreadCount);
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  /// Background refresh for unread count cache
  Future<void> _refreshUnreadCountCache() async {
    try {
      final count = await _remoteDataSource.getUnreadCount();
      await _localDataSource.cacheUnreadCount(count);
    } catch (e) {
      // Silent fail for background refresh
    }
  }
}

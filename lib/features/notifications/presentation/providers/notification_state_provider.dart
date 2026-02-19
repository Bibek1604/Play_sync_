import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/services/socket_service.dart';
import 'package:play_sync_new/features/notifications/domain/entities/notification.dart';
import 'package:play_sync_new/features/notifications/presentation/providers/notification_providers.dart';

/// Notification State
class NotificationState {
  final List<Notification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<Notification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Notification> get unreadNotifications =>
      notifications.where((n) => !n.read).toList();

  List<Notification> get readNotifications =>
      notifications.where((n) => n.read).toList();
}

/// Notification Notifier
///
/// Handles both HTTP-loaded and real-time socket-pushed notifications.
/// The backend automatically places each user in their personal room
/// `user:{userId}` on socket connection, so no manual room join is needed.
class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;
  late final SocketService _socket;

  NotificationNotifier(this.ref) : super(NotificationState()) {
    _socket = ref.read(notificationSocketServiceProvider);
    _subscribeSocketEvents();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Socket subscriptions
  // ─────────────────────────────────────────────────────────────────────────

  void _subscribeSocketEvents() {
    // New notification pushed in real-time
    _socket.on(ApiEndpoints.socketNotification, _onSocketNotification);

    // Unread count update pushed after any relevant action
    _socket.on(
        ApiEndpoints.socketNotificationUnreadCount, _onUnreadCountUpdate);
  }

  void _onSocketNotification(dynamic data) {
    try {
      if (data is! Map<String, dynamic>) return;

      final notification = Notification(
        id: data['id']?.toString() ?? '',
        userId: data['userId']?.toString() ?? '',
        type: NotificationType.fromString(data['type']?.toString() ?? ''),
        title: data['title']?.toString() ?? '',
        message: data['message']?.toString() ?? '',
        data: (data['data'] as Map?)?.cast<String, dynamic>() ?? {},
        link: data['link']?.toString(),
        read: data['read'] == true,
        createdAt: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

      if (notification.id.isEmpty) return;

      // Prepend — most recent first, avoid duplicates
      final existing = state.notifications.any((n) => n.id == notification.id);
      if (existing) return;

      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: notification.read ? state.unreadCount : state.unreadCount + 1,
      );
    } catch (e) {
      // Non-fatal — log and continue
      print('[NotificationNotifier] _onSocketNotification error: $e');
    }
  }

  void _onUnreadCountUpdate(dynamic data) {
    try {
      if (data is Map && data['count'] != null) {
        state = state.copyWith(unreadCount: data['count'] as int);
      }
    } catch (e) {
      print('[NotificationNotifier] _onUnreadCountUpdate error: $e');
    }
  }

  @override
  void dispose() {
    _socket.off(ApiEndpoints.socketNotification, _onSocketNotification);
    _socket.off(
        ApiEndpoints.socketNotificationUnreadCount, _onUnreadCountUpdate);
    super.dispose();
  }

  /// Load notifications
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final getNotifications = ref.read(getNotificationsUseCaseProvider);
      final result = await getNotifications();

      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        isLoading: false,
      );

      // Also load unread count
      await loadUnreadCount();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load unread count
  Future<void> loadUnreadCount() async {
    try {
      final getUnreadCount = ref.read(getUnreadCountUseCaseProvider);
      final count = await getUnreadCount();

      state = state.copyWith(unreadCount: count);
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final markAsRead = ref.read(markAsReadUseCaseProvider);
      await markAsRead(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return Notification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            link: n.link,
            read: true,
            createdAt: n.createdAt,
            updatedAt: n.updatedAt,
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final markAllAsRead = ref.read(markAllAsReadUseCaseProvider);
      await markAllAsRead();

      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        return Notification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          message: n.message,
          data: n.data,
          link: n.link,
          read: true,
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications();
  }
}

/// Notification State Provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

/// Unread count provider (for badges)
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider.select((state) => state.unreadCount));
});

/// Unread notifications provider
final unreadNotificationsProvider = Provider<List<Notification>>((ref) {
  return ref.watch(notificationProvider.select((state) => state.unreadNotifications));
});

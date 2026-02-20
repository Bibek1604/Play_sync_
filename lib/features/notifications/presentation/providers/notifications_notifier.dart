import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_client.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationsState extends Equatable {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props =>
      [notifications, isLoading, error, unreadCount];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;

  NotificationsNotifier(this._apiClient)
      : super(const NotificationsState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp =
          await _apiClient.get(ApiEndpoints.getNotifications);
      final data = resp.data as Map<String, dynamic>;
      final list =
          (data['notifications'] as List? ?? data['data'] as List? ?? [])
              .map((j) => NotificationEntity.fromJson(
                  j as Map<String, dynamic>))
              .toList();
      final unread = list.where((n) => !n.isRead).length;
      state = state.copyWith(
          notifications: list,
          isLoading: false,
          unreadCount: unread);
    } on DioException {
      final mock = _mockNotifications();
      state = state.copyWith(
        notifications: mock,
        isLoading: false,
        unreadCount: mock.where((n) => !n.isRead).length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _apiClient.patch(ApiEndpoints.markNotificationRead(id));
      final updated = state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    } catch (_) {
      // Optimistically update anyway
      final updated = state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      );
    }
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.patch(ApiEndpoints.markAllNotificationsRead);
    } catch (_) {}
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state =
        state.copyWith(notifications: updated, unreadCount: 0);
  }

  List<NotificationEntity> _mockNotifications() => [
        NotificationEntity(
          id: 'n1',
          type: 'join',
          message: 'Alex joined your Football game',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        NotificationEntity(
          id: 'n2',
          type: 'cancel',
          message: 'Chess Tournament has been cancelled',
          isRead: false,
          createdAt:
              DateTime.now().subtract(const Duration(hours: 3)),
        ),
        NotificationEntity(
          id: 'n3',
          type: 'win',
          message: 'Congratulations! You won the last match 🎉',
          isRead: true,
          createdAt:
              DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
}

// ── Provider ──────────────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient);
});

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../domain/entities/notification_entity.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/socket_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationsState extends Equatable {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final bool hasMore;
  final int page;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.hasMore = true,
    this.page = 1,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? unreadCount,
    bool? hasMore,
    int? page,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props =>
      [notifications, isLoading, error, unreadCount, hasMore, page];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;
  final Ref _ref;
  io.Socket? _socket;
  StreamSubscription? _socketStateSub;

  NotificationsNotifier(this._apiClient, this._ref)
      : super(const NotificationsState()) {
    fetchNotifications();
    _fetchUnreadCount();
    _initSocket();
  }

  // ── Socket integration ────────────────────────────────────────────────

  void _initSocket() {
    final authState = _ref.read(authNotifierProvider);
    final token = authState.user?.token;
    final userId = authState.user?.userId;

    if (token == null || userId == null) return;

    try {
      _socket = SocketService.instance.getSocket(token: token);

      // Backend auto-joins user:{userId} room on connect (no need to emit join)

      // Listen for new notifications
      _socket!.on('notification', (data) {
        if (data is Map<String, dynamic>) {
          final notification = NotificationEntity.fromJson(data);
          // Prepend to list
          final updated = [notification, ...state.notifications];
          state = state.copyWith(
            notifications: updated,
            unreadCount: state.unreadCount + 1,
          );
        }
      });

      // Listen for unread count updates
      _socket!.on('notification:unread-count', (data) {
        if (data is Map<String, dynamic>) {
          final count = data['count'] as int? ?? state.unreadCount;
          state = state.copyWith(unreadCount: count);
        }
      });

      // Listen for notification read events (from other devices)
      _socket!.on('notification:read', (data) {
        if (data is Map<String, dynamic>) {
          final notifId = data['notificationId'] as String?;
          if (notifId != null) {
            final updated = state.notifications
                .map((n) => n.id == notifId ? n.copyWith(read: true) : n)
                .toList();
            state = state.copyWith(
              notifications: updated,
              unreadCount: updated.where((n) => !n.read).length,
            );
          }
        }
      });

      // Listen for all-read events
      _socket!.on('notification:all-read', (_) {
        final updated =
            state.notifications.map((n) => n.copyWith(read: true)).toList();
        state = state.copyWith(notifications: updated, unreadCount: 0);
      });

      debugPrint('[Notifications] Socket listeners registered');
    } catch (e) {
      debugPrint('[Notifications] Socket init error: $e');
    }
  }

  // ── API calls ─────────────────────────────────────────────────────────

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, clearError: true, page: 1);
    try {
      final resp = await _apiClient.get(
        ApiEndpoints.getNotifications,
        queryParameters: {'page': 1, 'limit': 20},
      );
      final data = resp.data as Map<String, dynamic>;
      final innerData = data['data'] as Map<String, dynamic>? ?? data;
      final list = (innerData['notifications'] as List? ?? [])
          .map((j) =>
              NotificationEntity.fromJson(j as Map<String, dynamic>))
          .toList();
      final unread = innerData['unreadCount'] as int? ??
          list.where((n) => !n.read).length;
      final pagination =
          innerData['pagination'] as Map<String, dynamic>? ?? {};
      final totalPages = pagination['totalPages'] as int? ?? 1;

      state = state.copyWith(
        notifications: list,
        isLoading: false,
        unreadCount: unread,
        page: 1,
        hasMore: 1 < totalPages,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message']?.toString() ??
            'Failed to load notifications',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _apiClient.get(
        ApiEndpoints.getNotifications,
        queryParameters: {'page': nextPage, 'limit': 20},
      );
      final data = resp.data as Map<String, dynamic>;
      final innerData = data['data'] as Map<String, dynamic>? ?? data;
      final list = (innerData['notifications'] as List? ?? [])
          .map((j) =>
              NotificationEntity.fromJson(j as Map<String, dynamic>))
          .toList();
      final pagination =
          innerData['pagination'] as Map<String, dynamic>? ?? {};
      final totalPages = pagination['totalPages'] as int? ?? 1;

      state = state.copyWith(
        notifications: [...state.notifications, ...list],
        isLoading: false,
        page: nextPage,
        hasMore: nextPage < totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final resp = await _apiClient.get(
        ApiEndpoints.getUnreadNotificationsCount,
      );
      final data = resp.data as Map<String, dynamic>;
      final innerData = data['data'] as Map<String, dynamic>? ?? data;
      final count = innerData['count'] as int? ??
          innerData['unreadCount'] as int? ??
          0;
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    // Optimistic update
    final updated = state.notifications
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.read).length,
    );
    try {
      await _apiClient.patch(ApiEndpoints.markNotificationRead(id));
    } catch (_) {
      // Keep optimistic state
    }
  }

  Future<void> markAllRead() async {
    // Optimistic update
    final updated =
        state.notifications.map((n) => n.copyWith(read: true)).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
    try {
      await _apiClient.patch(ApiEndpoints.markAllNotificationsRead);
    } catch (_) {}
  }

  @override
  void dispose() {
    _socketStateSub?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient, ref);
});

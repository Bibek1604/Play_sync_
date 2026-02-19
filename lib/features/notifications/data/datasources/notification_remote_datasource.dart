import 'dart:async';
import 'package:dio/dio.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/services/socket_service.dart';
import 'package:play_sync_new/features/notifications/data/models/notification_dto.dart';

class NotificationRemoteDataSource {
  final Dio dio;
  final SocketService socketService;

  NotificationRemoteDataSource(this.dio, this.socketService);

  Future<NotificationListResultDto> getNotifications({
    required int page,
    required int limit,
    bool? unread,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (unread != null) 'unread': unread,
      };

      final response = await dio.get(
        ApiEndpoints.notificationsList,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? response.data;
      return NotificationListResultDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data['data'] ?? response.data;
      
      return data['unreadCount'] ?? data['unread_count'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await dio.patch(ApiEndpoints.notificationsReadAll);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final endpoint = ApiEndpoints.notificationsMarkRead.replaceAll(':id', id);
      await dio.patch(endpoint);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Stream<NotificationDto> watchNotifications() {
    final controller = StreamController<NotificationDto>.broadcast();
    
    // Listen for notification events on already-connected socket
    // Note: Socket should be initialized with token elsewhere in the app
    socketService.on('notification', (data) {
      try {
        final notification = NotificationDto.fromJson(data as Map<String, dynamic>);
        controller.add(notification);
      } catch (e) {
        // Ignore invalid notifications
      }
    });
    
    return controller.stream;
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['message'] ?? 'An error occurred';
      return Exception(message);
    }
    return Exception('Network error');
  }
}

class NotificationListResultDto {
  final List<NotificationDto> notifications;
  final int unreadCount;
  final PaginationDto pagination;

  NotificationListResultDto({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });

  factory NotificationListResultDto.fromJson(Map<String, dynamic> json) {
    final notificationsList = json['notifications'] as List<dynamic>? ?? [];
    
    return NotificationListResultDto(
      notifications: notificationsList
          .map((item) => NotificationDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      pagination: PaginationDto.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationDto {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationDto({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationDto.fromJson(Map<String, dynamic> json) {
    return PaginationDto(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
    );
  }
}

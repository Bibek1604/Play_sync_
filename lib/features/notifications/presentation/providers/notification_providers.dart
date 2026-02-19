import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/services/socket_service.dart';
import 'package:play_sync_new/features/notifications/domain/repositories/notification_repository.dart';
import 'package:play_sync_new/features/notifications/domain/usecases/get_notifications.dart';
import 'package:play_sync_new/features/notifications/domain/usecases/get_unread_count.dart';
import 'package:play_sync_new/features/notifications/domain/usecases/mark_as_read.dart';
import 'package:play_sync_new/features/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:play_sync_new/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:play_sync_new/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:play_sync_new/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:hive/hive.dart';

/// Dependency Injection Providers for Notifications Feature

// Dio provider
final notificationDioProvider = Provider<Dio>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.dio;
});

// Socket service provider
final notificationSocketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

// Remote data source provider
final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(
    ref.watch(notificationDioProvider),
    ref.watch(notificationSocketServiceProvider),
  );
});

// Hive box provider
final notificationMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('notifications_metadata');
});

// Local data source provider
final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource(ref.watch(notificationMetadataBoxProvider));
});

// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDataSourceProvider),
    ref.watch(notificationLocalDataSourceProvider),
  );
});

// Use case providers
final getNotificationsUseCaseProvider = Provider<GetNotifications>((ref) {
  return GetNotifications(ref.watch(notificationRepositoryProvider));
});

final getUnreadCountUseCaseProvider = Provider<GetUnreadCount>((ref) {
  return GetUnreadCount(ref.watch(notificationRepositoryProvider));
});

final markAsReadUseCaseProvider = Provider<MarkAsRead>((ref) {
  return MarkAsRead(ref.watch(notificationRepositoryProvider));
});

final markAllAsReadUseCaseProvider = Provider<MarkAllAsRead>((ref) {
  return MarkAllAsRead(ref.watch(notificationRepositoryProvider));
});

import 'package:play_sync_new/features/notifications/domain/repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Future<NotificationListResult> call({
    int page = 1,
    int limit = 20,
    bool? unread,
  }) async {
    if (page < 1) {
      throw ArgumentError('Page must be at least 1');
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }

    return await repository.getNotifications(
      page: page,
      limit: limit,
      unread: unread,
    );
  }
}

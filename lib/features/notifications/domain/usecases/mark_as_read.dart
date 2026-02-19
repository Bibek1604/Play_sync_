import 'package:play_sync_new/features/notifications/domain/repositories/notification_repository.dart';

class MarkAsRead {
  final NotificationRepository repository;

  MarkAsRead(this.repository);

  Future<void> call(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('Notification ID cannot be empty');
    }

    return await repository.markAsRead(id);
  }
}

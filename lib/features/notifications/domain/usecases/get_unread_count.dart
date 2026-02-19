import 'package:play_sync_new/features/notifications/domain/repositories/notification_repository.dart';

class GetUnreadCount {
  final NotificationRepository repository;

  GetUnreadCount(this.repository);

  Future<int> call() async {
    return repository.getUnreadCount();
  }
}

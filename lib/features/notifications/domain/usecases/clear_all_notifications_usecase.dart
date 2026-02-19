import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/notifications/domain/repositories/notification_repository.dart';

/// Deletes all notifications for the current user.
class ClearAllNotificationsUsecase implements UsecaseWithoutParams<void> {
  final INotificationRepository _repository;

  const ClearAllNotificationsUsecase({
    required INotificationRepository repository,
  }) : _repository = repository;

  @override
  Future<Either<Failure, void>> call() {
    return _repository.clearAll();
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LogoutUsecase(repository: repository);
});

/// Clears local tokens and session data, disconnecting the user.
class LogoutUsecase implements UsecaseWithoutParams<void> {
  final IAuthRepository _repository;

  const LogoutUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call() async {
    return _repository.logout();
  }
}

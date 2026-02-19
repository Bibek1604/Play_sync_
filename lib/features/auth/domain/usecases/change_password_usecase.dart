import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final changePasswordUsecaseProvider = Provider<ChangePasswordUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return ChangePasswordUsecase(repository: repository);
});

class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });
}

/// Changes the authenticated user's password.
class ChangePasswordUsecase
    implements UsecaseWithParams<void, ChangePasswordParams> {
  final IAuthRepository _repository;

  const ChangePasswordUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(ChangePasswordParams params) {
    return _repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

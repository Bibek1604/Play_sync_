import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final forgotPasswordUsecaseProvider = Provider<ForgotPasswordUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return ForgotPasswordUsecase(repository: repository);
});

class ForgotPasswordParams {
  final String email;
  const ForgotPasswordParams({required this.email});
}

/// Sends a password-reset link to the given email address.
class ForgotPasswordUsecase
    implements UsecaseWithParams<void, ForgotPasswordParams> {
  final IAuthRepository _repository;

  const ForgotPasswordUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(ForgotPasswordParams params) {
    return _repository.forgotPassword(email: params.email);
  }
}

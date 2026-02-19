import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final refreshTokenUsecaseProvider = Provider<RefreshTokenUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return RefreshTokenUsecase(repository: repository);
});

/// Silently refreshes the access token using the stored refresh token.
/// Should be called when a 401 response is received.
class RefreshTokenUsecase implements UsecaseWithoutParams<String> {
  final IAuthRepository _repository;

  const RefreshTokenUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, String>> call() {
    return _repository.refreshToken();
  }
}

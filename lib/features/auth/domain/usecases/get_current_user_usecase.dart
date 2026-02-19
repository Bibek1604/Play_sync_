import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return GetCurrentUserUsecase(repository: repository);
});

/// Returns the currently cached authenticated user, if any.
class GetCurrentUserUsecase implements UsecaseWithoutParams<AuthEntity?> {
  final IAuthRepository _repository;

  const GetCurrentUserUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, AuthEntity?>> call() {
    return _repository.getCurrentUser();
  }
}

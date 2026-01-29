import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

final getProfileUsecaseProvider = Provider<GetProfileUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return GetProfileUsecase(repository: repository);
});

/// Use case for getting user profile
class GetProfileUsecase {
  final IProfileRepository _repository;

  GetProfileUsecase({required IProfileRepository repository})
      : _repository = repository;

  Future<Either<Failure, ProfileEntity>> call() async {
    return await _repository.getProfile();
  }
}

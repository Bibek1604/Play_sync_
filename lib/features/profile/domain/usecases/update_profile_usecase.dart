import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UpdateProfileUsecase(repository: repository);
});

/// Parameters for updating profile
class UpdateProfileParams {
  final String? name;
  final String? number;
  final String? favouriteGame;
  final String? place;
  final String? avatar;
  final String? currentPassword;
  final String? changePassword;

  UpdateProfileParams({
    this.name,
    this.number,
    this.favouriteGame,
    this.place,
    this.avatar,
    this.currentPassword,
    this.changePassword,
  });
}

/// Use case for updating user profile
class UpdateProfileUsecase {
  final IProfileRepository _repository;

  UpdateProfileUsecase({required IProfileRepository repository})
      : _repository = repository;

  Future<Either<Failure, ProfileEntity>> call(UpdateProfileParams params) async {
    return await _repository.updateProfile(
      name: params.name,
      number: params.number,
      favouriteGame: params.favouriteGame,
      place: params.place,
      avatar: params.avatar,
      currentPassword: params.currentPassword,
      changePassword: params.changePassword,
    );
  }
}

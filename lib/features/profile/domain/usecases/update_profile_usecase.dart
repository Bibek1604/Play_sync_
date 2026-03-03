import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  final String? fullName;
  final String? phone;
  final String? favoriteGame;
  final String? place;
  final String? bio;
  final String? currentPassword;
  final String? changePassword;
  final XFile? profilePicture;

  UpdateProfileParams({
    this.fullName,
    this.phone,
    this.favoriteGame,
    this.place,
    this.bio,
    this.currentPassword,
    this.changePassword,
    this.profilePicture,
  });
}

/// Use case for updating user profile
class UpdateProfileUsecase {
  final IProfileRepository _repository;

  UpdateProfileUsecase({required IProfileRepository repository})
      : _repository = repository;

  Future<Either<Failure, ProfileEntity>> call(UpdateProfileParams params) async {
    return await _repository.updateProfile(
      fullName: params.fullName,
      phone: params.phone,
      favoriteGame: params.favoriteGame,
      place: params.place,
      bio: params.bio,
      currentPassword: params.currentPassword,
      changePassword: params.changePassword,
      profilePicture: params.profilePicture,
    );
  }
}

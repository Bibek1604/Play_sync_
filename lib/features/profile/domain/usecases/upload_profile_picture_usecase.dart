import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

final uploadProfilePictureUsecaseProvider = Provider<UploadProfilePictureUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UploadProfilePictureUsecase(repository: repository);
});

/// Use case for uploading profile picture
class UploadProfilePictureUsecase {
  final IProfileRepository _repository;

  UploadProfilePictureUsecase({required IProfileRepository repository})
      : _repository = repository;

  Future<Either<Failure, String>> call(XFile image) async {
    // Validate file size (max 5MB)
    final fileSize = await image.length();
    if (fileSize > 5 * 1024 * 1024) {
      return const Left(ApiFailure(message: 'Image size must be less than 5MB'));
    }

    // Validate file extension
    final extension = image.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return const Left(ApiFailure(message: 'Invalid image format. Use JPG, PNG, GIF, or WebP'));
    }

    return await _repository.uploadProfilePicture(image);
  }
}

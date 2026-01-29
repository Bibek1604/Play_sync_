import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

final uploadCoverPictureUsecaseProvider = Provider<UploadCoverPictureUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UploadCoverPictureUsecase(repository: repository);
});

/// Use case for uploading cover picture
class UploadCoverPictureUsecase {
  final IProfileRepository _repository;

  UploadCoverPictureUsecase({required IProfileRepository repository})
      : _repository = repository;

  Future<Either<Failure, String>> call(XFile image) async {
    // Validate file size (max 5MB)
    final fileSize = await image.length();
    if (fileSize > 5 * 1024 * 1024) {
      return const Left(ApiFailure(message: 'Image size must be less than 5MB'));
    }

    return await _repository.uploadCoverPicture(image);
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

final uploadGalleryPicturesUsecaseProvider = Provider<UploadGalleryPicturesUsecase>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UploadGalleryPicturesUsecase(repository: repository);
});

/// Use case for uploading gallery pictures
class UploadGalleryPicturesUsecase {
  final IProfileRepository _repository;

  UploadGalleryPicturesUsecase({required IProfileRepository repository})
      : _repository = repository;

  Future<Either<Failure, List<String>>> call(List<XFile> images) async {
    if (images.isEmpty) {
      return const Right([]);
    }

    // Validate each image size (max 5MB)
    for (var image in images) {
      final fileSize = await image.length();
      if (fileSize > 5 * 1024 * 1024) {
        return Left(ApiFailure(message: 'Image ${image.name} exceeds 5MB limit'));
      }
    }

    return await _repository.uploadGalleryPictures(images);
  }
}

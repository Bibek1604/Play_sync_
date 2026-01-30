import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';

/// Abstract repository interface for profile operations
abstract interface class IProfileRepository {
  /// Get current user profile
  Future<Either<Failure, ProfileEntity>> getProfile();

  /// Update user profile
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? favouriteGame,
    String? place,
    String? currentPassword,
    String? changePassword,
    XFile? profilePicture,
  });

  /// Upload profile picture
  Future<Either<Failure, String>> uploadProfilePicture(XFile image);

  /// Upload cover picture
  Future<Either<Failure, String>> uploadCoverPicture(XFile image);

  /// Upload gallery pictures
  Future<Either<Failure, List<String>>> uploadGalleryPictures(List<XFile> images);

  /// Delete profile picture
  Future<Either<Failure, bool>> deleteProfilePicture();
}

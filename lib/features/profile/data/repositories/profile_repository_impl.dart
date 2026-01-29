import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

import 'package:play_sync_new/features/profile/data/models/update_profile_request_model.dart';

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final remoteDataSource = ref.read(profileRemoteDatasourceProvider);
  return ProfileRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Implementation of profile repository
class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final response = await _remoteDataSource.getProfile();
      return Right(response.toEntity());
    } catch (e) {
      debugPrint('[PROFILE REPO] Get profile error: $e');
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? name,
    String? number,
    String? favouriteGame,
    String? place,
    String? avatar,
    String? currentPassword,
    String? changePassword,
  }) async {
    try {
      final requestModel = UpdateProfileRequestModel(
        name: name,
        number: number,
        favouriteGame: favouriteGame,
        place: place,
        avatar: avatar,
        currentPassword: currentPassword,
        changePassword: changePassword,
      );

      final response = await _remoteDataSource.updateProfile(requestModel.toJson());
      return Right(response.toEntity());
    } catch (e) {
      debugPrint('[PROFILE REPO] Update profile error: $e');
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePicture(XFile image) async {
    try {
      final imageUrl = await _remoteDataSource.uploadProfilePicture(image);
      return Right(imageUrl);
    } catch (e) {
      debugPrint('[PROFILE REPO] Upload profile picture error: $e');
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCoverPicture(XFile image) async {
    try {
      final imageUrl = await _remoteDataSource.uploadCoverPicture(image);
      return Right(imageUrl);
    } catch (e) {
      debugPrint('[PROFILE REPO] Upload cover picture error: $e');
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadGalleryPictures(List<XFile> images) async {
    try {
      final imageUrls = await _remoteDataSource.uploadGalleryPictures(images);
      return Right(imageUrls);
    } catch (e) {
      debugPrint('[PROFILE REPO] Upload gallery pictures error: $e');
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteProfilePicture() async {
    try {
      final result = await _remoteDataSource.deleteProfilePicture();
      return Right(result);
    } catch (e) {
      debugPrint('[PROFILE REPO] Delete profile picture error: $e');
      return Left(ApiFailure(message: e.toString()));
    }
  }
}

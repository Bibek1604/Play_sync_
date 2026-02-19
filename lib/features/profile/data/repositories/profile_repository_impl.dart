import 'package:image_picker/image_picker.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:play_sync_new/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

import 'package:play_sync_new/features/profile/data/models/update_profile_request_model.dart';

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final remoteDataSource = ref.read(profileRemoteDatasourceProvider);
  final localDataSource = ref.read(profileLocalDataSourceProvider);
  return ProfileRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

/// Implementation of profile repository with cache-first strategy
class ProfileRepositoryImpl implements IProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource? _localDataSource;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    ProfileLocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      // Try to get from cache first if local datasource is available
      if (_localDataSource != null && _localDataSource.hasCachedProfile()) {
        final cachedProfile = await _localDataSource.getCachedProfile();
        if (cachedProfile != null) {
          // Return cached data immediately
          final entity = cachedProfile.toEntity();
          
          // Refresh cache in background
          _refreshProfileCache();
          
          return Right(entity);
        }
      }
      
      // Fetch from remote
      final response = await _remoteDataSource.getProfile();
      
      // Cache the result if local datasource is available
      if (_localDataSource != null) {
        await _localDataSource.cacheProfile(response);
      }
      
      return Right(response.toEntity());
    } catch (e) {
      debugPrint('[PROFILE REPO] Get profile error: $e');
      
      // If remote fails, try to return cached data as fallback
      if (_localDataSource != null) {
        final cachedProfile = await _localDataSource.getCachedProfile();
        if (cachedProfile != null) {
          return Right(cachedProfile.toEntity());
        }
      }
      
      return Left(ApiFailure(message: e.toString()));
    }
  }

  /// Background refresh for profile cache
  Future<void> _refreshProfileCache() async {
    try {
      final response = await _remoteDataSource.getProfile();
      if (_localDataSource != null) {
        await _localDataSource.cacheProfile(response);
      }
    } catch (e) {
      // Silent fail - we already have cached data
      debugPrint('[PROFILE REPO] Background refresh failed: $e');
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? favouriteGame,
    String? place,
    String? currentPassword,
    String? changePassword,
    XFile? profilePicture,
  }) async {
    try {
      final requestModel = UpdateProfileRequestModel(
        fullName: fullName,
        phone: phone,
        favouriteGame: favouriteGame,
        place: place,
        currentPassword: currentPassword,
        changePassword: changePassword,
      );

      final response = await _remoteDataSource.updateProfile(
        requestModel.toFormDataMap(),
        profilePicture: profilePicture,
      );
      
      // Update cache if local datasource is available
      if (_localDataSource != null) {
        await _localDataSource.cacheProfile(response);
      }
      
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

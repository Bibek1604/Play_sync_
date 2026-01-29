import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:play_sync_new/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:play_sync_new/features/profile/domain/usecases/upload_profile_picture_usecase.dart';
import 'package:play_sync_new/features/profile/presentation/state/profile_state.dart';

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final getProfileUsecase = ref.read(getProfileUsecaseProvider);
  final updateProfileUsecase = ref.read(updateProfileUsecaseProvider);
  final uploadProfilePictureUsecase = ref.read(uploadProfilePictureUsecaseProvider);

  return ProfileNotifier(
    getProfileUsecase: getProfileUsecase,
    updateProfileUsecase: updateProfileUsecase,
    uploadProfilePictureUsecase: uploadProfilePictureUsecase,
  );
});

/// Profile Notifier - Manages profile state
class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUsecase _getProfileUsecase;
  final UpdateProfileUsecase _updateProfileUsecase;
  final UploadProfilePictureUsecase _uploadProfilePictureUsecase;

  ProfileNotifier({
    required GetProfileUsecase getProfileUsecase,
    required UpdateProfileUsecase updateProfileUsecase,
    required UploadProfilePictureUsecase uploadProfilePictureUsecase,
  })  : _getProfileUsecase = getProfileUsecase,
        _updateProfileUsecase = updateProfileUsecase,
        _uploadProfilePictureUsecase = uploadProfilePictureUsecase,
        super(const ProfileState());

  /// Get user profile
  Future<void> getProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getProfileUsecase();

    result.fold(
      (failure) {
        debugPrint('[PROFILE NOTIFIER] Get profile failed: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (profile) {
        debugPrint('[PROFILE NOTIFIER] Profile loaded successfully');
        state = state.copyWith(
          isLoading: false,
          profile: profile,
          clearError: true,
        );
      },
    );
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? number,
    String? favouriteGame,
    String? place,
    String? avatar,
    String? currentPassword,
    String? changePassword,
  }) async {
    state = state.copyWith(isUpdating: true, clearError: true, clearSuccess: true);

    final params = UpdateProfileParams(
      name: name,
      number: number,
      favouriteGame: favouriteGame,
      place: place,
      avatar: avatar,
      currentPassword: currentPassword,
      changePassword: changePassword,
    );

    final result = await _updateProfileUsecase(params);

    result.fold(
      (failure) {
        debugPrint('[PROFILE NOTIFIER] Update profile failed: ${failure.message}');
        state = state.copyWith(
          isUpdating: false,
          error: failure.message,
        );
      },
      (profile) {
        debugPrint('[PROFILE NOTIFIER] Profile updated successfully');
        state = state.copyWith(
          isUpdating: false,
          profile: profile,
          successMessage: 'Profile updated successfully',
          clearError: true,
        );
      },
    );
  }

  /// Upload profile picture
  Future<void> uploadProfilePicture(XFile image) async {
    state = state.copyWith(
      isUploadingPicture: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _uploadProfilePictureUsecase(image);

    result.fold(
      (failure) {
        debugPrint('[PROFILE NOTIFIER] Upload picture failed: ${failure.message}');
        state = state.copyWith(
          isUploadingPicture: false,
          error: failure.message,
        );
      },
      (imageUrl) {
        debugPrint('[PROFILE NOTIFIER] Picture uploaded successfully: $imageUrl');
        
        // Update profile with new picture URL
        final updatedProfile = state.profile?.copyWith(profilePicture: imageUrl);
        
        state = state.copyWith(
          isUploadingPicture: false,
          profile: updatedProfile,
          successMessage: 'Profile picture updated successfully',
          clearError: true,
        );
      },
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Reset state
  void reset() {
    state = const ProfileState();
  }
}

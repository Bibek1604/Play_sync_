import 'package:equatable/equatable.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';

/// Profile State
class ProfileState extends Equatable {
  final bool isLoading;
  final ProfileEntity? profile;
  final String? error;
  final bool isUpdating;
  final bool isUploadingPicture;
  final String? successMessage;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
    this.isUpdating = false,
    this.isUploadingPicture = false,
    this.successMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    ProfileEntity? profile,
    String? error,
    bool? isUpdating,
    bool? isUploadingPicture,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: clearError ? null : (error ?? this.error),
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingPicture: isUploadingPicture ?? this.isUploadingPicture,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        profile,
        error,
        isUpdating,
        isUploadingPicture,
        successMessage,
      ];
}

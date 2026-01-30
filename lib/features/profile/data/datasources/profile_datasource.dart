import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/profile/data/models/profile_response_model.dart';

/// Abstract interface for profile data source
abstract interface class IProfileDataSource {
  /// Get current user profile
  Future<ProfileResponseModel> getProfile();

  /// Update user profile
  Future<ProfileResponseModel> updateProfile(
    Map<String, dynamic> profileData, {
    XFile? profilePicture,
  });

  /// Upload profile picture
  Future<String> uploadProfilePicture(XFile image);

  /// Upload cover picture
  Future<String> uploadCoverPicture(XFile image);

  /// Upload gallery pictures
  Future<List<String>> uploadGalleryPictures(List<XFile> images);

  /// Delete profile picture
  Future<bool> deleteProfilePicture();
}

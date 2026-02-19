import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:play_sync_new/features/profile/data/models/profile_response_model.dart';

/// Dependency Injection Providers

final profileBoxProvider = Provider<Box<ProfileResponseModel>>((ref) {
  return Hive.box<ProfileResponseModel>('profile');
});

final profileMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('profile_metadata');
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource(
    ref.watch(profileBoxProvider),
    ref.watch(profileMetadataBoxProvider),
  );
});

/// Profile Local Data Source (Data Layer)
/// 
/// Handles local caching of profile data using Hive
class ProfileLocalDataSource {
  final Box<ProfileResponseModel> _profileBox;
  final Box<dynamic> _metadataBox;
  
  static const String _currentProfileKey = 'current_profile';
  static const String _profileTimestampKey = 'profile_timestamp';

  ProfileLocalDataSource(this._profileBox, this._metadataBox);

  /// Save profile to local cache
  Future<void> cacheProfile(ProfileResponseModel profile) async {
    try {
      await _profileBox.put(_currentProfileKey, profile);
      await _updateCacheTimestamp();
    } catch (e) {
      throw Exception('Failed to cache profile: $e');
    }
  }

  /// Get cached profile
  Future<ProfileResponseModel?> getCachedProfile() async {
    try {
      if (_isCacheExpired()) {
        return null;
      }
      return _profileBox.get(_currentProfileKey);
    } catch (e) {
      throw Exception('Failed to get cached profile: $e');
    }
  }

  /// Check if profile cache exists and is valid
  bool hasCachedProfile() {
    return _profileBox.containsKey(_currentProfileKey) && !_isCacheExpired();
  }

  /// Clear cached profile
  Future<void> clearCache() async {
    try {
      await _profileBox.delete(_currentProfileKey);
      await _metadataBox.delete(_profileTimestampKey);
    } catch (e) {
      throw Exception('Failed to clear profile cache: $e');
    }
  }

  /// Update specific fields in cached profile
  Future<void> updateCachedProfile(Map<String, dynamic> updates) async {
    try {
      final cachedProfile = _profileBox.get(_currentProfileKey);
      if (cachedProfile == null) return;

      // Create updated profile with new values
      final updatedProfile = ProfileResponseModel(
        userId: updates['userId'] as String? ?? cachedProfile.userId,
        fullName: updates['fullName'] as String? ?? cachedProfile.fullName,
        email: updates['email'] as String? ?? cachedProfile.email,
        phoneNumber: updates['phoneNumber'] as String? ?? cachedProfile.phoneNumber,
        bio: updates['bio'] as String? ?? cachedProfile.bio,
        profilePicture: updates['profilePicture'] as String? ?? cachedProfile.profilePicture,
        location: updates['location'] as String? ?? cachedProfile.location,
        dateOfBirth: updates['dateOfBirth'] as String? ?? cachedProfile.dateOfBirth,
        favouriteGame: updates['favouriteGame'] as String? ?? cachedProfile.favouriteGame,
        gamingPlatform: updates['gamingPlatform'] as String? ?? cachedProfile.gamingPlatform,
        skillLevel: updates['skillLevel'] as String? ?? cachedProfile.skillLevel,
        createdAt: cachedProfile.createdAt,
        updatedAt: DateTime.now(),
      );

      await _profileBox.put(_currentProfileKey, updatedProfile);
      await _updateCacheTimestamp();
    } catch (e) {
      throw Exception('Failed to update cached profile: $e');
    }
  }

  /// Get cache age in minutes
  int? getCacheAgeMinutes() {
    final timestamp = _metadataBox.get(_profileTimestampKey);
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes;
  }

  /// Private: Update cache timestamp
  Future<void> _updateCacheTimestamp() async {
    await _metadataBox.put(_profileTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Private: Check if cache is expired (15 minutes)
  bool _isCacheExpired() {
    final timestamp = _metadataBox.get(_profileTimestampKey);
    if (timestamp == null) return true;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    // Cache expires after 15 minutes
    return difference.inMinutes > 15;
  }
}

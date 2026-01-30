import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';

/// API Response model for profile
class ProfileResponseModel {
  final String? userId;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? bio;
  final String? profilePicture;
  final String? location;
  final String? dateOfBirth;
  final String? favouriteGame;
  final String? gamingPlatform;
  final String? skillLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileResponseModel({
    this.userId,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.bio,
    this.profilePicture,
    this.location,
    this.dateOfBirth,
    this.favouriteGame,
    this.gamingPlatform,
    this.skillLevel,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from JSON response
  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    // Check if response has nested data/profile object
    final Map<String, dynamic> profileData;
    if (json.containsKey('data') && json['data'] is Map) {
      profileData = json['data'] as Map<String, dynamic>;
    } else if (json.containsKey('profile') && json['profile'] is Map) {
      profileData = json['profile'] as Map<String, dynamic>;
    } else {
      profileData = json;
    }

    return ProfileResponseModel(
      userId: profileData['_id'] ?? profileData['userId'] ?? profileData['id'],
      fullName: profileData['fullName'] ?? profileData['full_name'] ?? profileData['name'],
      email: profileData['email'],
      phoneNumber: profileData['phone'] ?? profileData['phoneNumber'] ?? profileData['phone_number'] ?? profileData['number'],
      bio: profileData['bio'] ?? profileData['description'],
      profilePicture: _getImageUrl(profileData['profilePicture'] ?? 
                      profileData['profile_picture'] ?? 
                      profileData['avatar'] ?? 
                      profileData['image']),
      location: profileData['place'] ?? profileData['location'],
      dateOfBirth: profileData['dateOfBirth'] ?? profileData['date_of_birth'] ?? profileData['dob'],
      favouriteGame: profileData['favouriteGame']?.toString() ?? profileData['favoriteGame']?.toString(),
      gamingPlatform: profileData['gamingPlatform'] ?? profileData['gaming_platform'] ?? profileData['platform'],
      skillLevel: profileData['skillLevel'] ?? profileData['skill_level'] ?? profileData['level'],
      createdAt: profileData['createdAt'] != null
          ? DateTime.tryParse(profileData['createdAt'].toString())
          : null,
      updatedAt: profileData['updatedAt'] != null
          ? DateTime.tryParse(profileData['updatedAt'].toString())
          : null,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (bio != null) 'bio': bio,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (location != null) 'location': location,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (favouriteGame != null) 'favouriteGame': favouriteGame,
      if (gamingPlatform != null) 'gamingPlatform': gamingPlatform,
      if (skillLevel != null) 'skillLevel': skillLevel,
    };
  }

  /// Convert to Domain Entity
  ProfileEntity toEntity() {
    return ProfileEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      bio: bio,
      profilePicture: profilePicture,
      location: location,
      dateOfBirth: dateOfBirth,
      favouriteGame: favouriteGame,
      gamingPlatform: gamingPlatform,
      skillLevel: skillLevel,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  /// Helper to construct full image URL
  static String? _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    
    // Remove leading slash if present to avoid double slash
    final cleanPath = path.startsWith('/') ? path : '/$path';
    
    return '${ApiEndpoints.imageBaseUrl}$cleanPath';
  }
}

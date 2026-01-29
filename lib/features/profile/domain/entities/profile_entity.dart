import 'package:equatable/equatable.dart';

/// Profile Entity - Represents user profile data in domain layer
class ProfileEntity extends Equatable {
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

  const ProfileEntity({
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

  /// Copy with method for immutability
  ProfileEntity copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? bio,
    String? profilePicture,
    String? location,
    String? dateOfBirth,
    String? favouriteGame,
    String? gamingPlatform,
    String? skillLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      favouriteGame: favouriteGame ?? this.favouriteGame,
      gamingPlatform: gamingPlatform ?? this.gamingPlatform,
      skillLevel: skillLevel ?? this.skillLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        email,
        phoneNumber,
        bio,
        profilePicture,
        location,
        dateOfBirth,
        favouriteGame,
        gamingPlatform,
        skillLevel,
        createdAt,
        updatedAt,
      ];
}

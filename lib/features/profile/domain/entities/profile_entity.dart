import 'package:equatable/equatable.dart';

/// Profile Entity - Represents user profile data in domain layer
/// Aligned with backend User model (GET /users/me)
class ProfileEntity extends Equatable {
  final String? userId;
  final String? fullName;
  final String? email;
  final String? role;
  final String? avatar;
  final String? bio;
  final String? phone;
  final String? favoriteGame;
  final String? place;
  final int totalGames;
  final int wins;
  final int losses;
  final double winRate;
  final int xp;
  final int level;
  final DateTime? lastActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileEntity({
    this.userId,
    this.fullName,
    this.email,
    this.role,
    this.avatar,
    this.bio,
    this.phone,
    this.favoriteGame,
    this.place,
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.winRate = 0,
    this.xp = 0,
    this.level = 1,
    this.lastActive,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed: XP progress to next level (0.0 - 1.0)
  double get xpProgress {
    if (level <= 0) return 0;
    final currentLevelXp = (level - 1) * (level - 1) * 100;
    final nextLevelXp = level * level * 100;
    final range = nextLevelXp - currentLevelXp;
    if (range <= 0) return 0;
    return ((xp - currentLevelXp) / range).clamp(0.0, 1.0);
  }

  /// Computed: initials for avatar fallback
  String get initials {
    if (fullName == null || fullName!.isEmpty) return '?';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  /// Copy with method for immutability
  ProfileEntity copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? role,
    String? avatar,
    String? bio,
    String? phone,
    String? favoriteGame,
    String? place,
    int? totalGames,
    int? wins,
    int? losses,
    double? winRate,
    int? xp,
    int? level,
    DateTime? lastActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      favoriteGame: favoriteGame ?? this.favoriteGame,
      place: place ?? this.place,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      winRate: winRate ?? this.winRate,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId, fullName, email, role, avatar, bio, phone,
        favoriteGame, place, totalGames, wins, losses, winRate,
        xp, level, lastActive, createdAt, updatedAt,
      ];
}

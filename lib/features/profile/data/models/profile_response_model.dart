import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';

/// API Response model for profile — maps backend User JSON to ProfileEntity
class ProfileResponseModel {
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

  ProfileResponseModel({
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

  /// Parse from JSON response — handles both flat and nested { data: { ... } } shapes
  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> d;
    if (json.containsKey('data') && json['data'] is Map) {
      d = json['data'] as Map<String, dynamic>;
    } else if (json.containsKey('profile') && json['profile'] is Map) {
      d = json['profile'] as Map<String, dynamic>;
    } else {
      d = json;
    }

    return ProfileResponseModel(
      userId: d['_id'] ?? d['userId'] ?? d['id'],
      fullName: d['fullName'] ?? d['full_name'] ?? d['name'],
      email: d['email'],
      role: d['role'],
      avatar: _imageUrl(d['avatar'] ?? d['profilePicture'] ?? d['image']),
      bio: d['bio'] ?? d['description'],
      phone: d['phone'] ?? d['phoneNumber'],
      favoriteGame: d['favoriteGame']?.toString() ?? d['favouriteGame']?.toString(),
      place: d['place'] ?? d['location'],
      totalGames: _toInt(d['totalGames']),
      wins: _toInt(d['wins']),
      losses: _toInt(d['losses']),
      winRate: _toDouble(d['winRate']),
      xp: _toInt(d['xp']),
      level: _toInt(d['level'], fallback: 1),
      lastActive: _parseDate(d['lastActive']),
      createdAt: _parseDate(d['createdAt']),
      updatedAt: _parseDate(d['updatedAt']),
    );
  }

  /// Convert to JSON for API requests (PATCH /profile)
  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      if (phone != null) 'phone': phone,
      if (favoriteGame != null) 'favoriteGame': favoriteGame,
      if (place != null) 'place': place,
    };
  }

  /// Convert to Domain Entity
  ProfileEntity toEntity() {
    return ProfileEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      role: role,
      avatar: avatar,
      bio: bio,
      phone: phone,
      favoriteGame: favoriteGame,
      place: place,
      totalGames: totalGames,
      wins: wins,
      losses: losses,
      winRate: winRate,
      xp: xp,
      level: level,
      lastActive: lastActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
static String? _imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '${ApiEndpoints.imageBaseUrl}$cleanPath';
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

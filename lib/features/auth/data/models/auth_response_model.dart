import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';

/// API Response model for authentication
class AuthResponseModel {
  final String? userId;
  final String email;
  final String role;
  final String? token;
  final String? refreshToken;
  final String? message;
  final DateTime? createdAt;

  AuthResponseModel({
    this.userId,
    required this.email,
    required this.role,
    this.token,
    this.refreshToken,
    this.message,
    this.createdAt,
  });

  /// Parse from JSON response
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      userId: json['userId'] ?? json['id'] ?? json['_id'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      token: json['token'] ?? json['accessToken'] ?? json['access_token'],
      refreshToken:
          json['refreshToken'] ?? json['refresh_token'] ?? json['refToken'],
      message: json['message'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Convert to Domain Entity
  AuthEntity toEntity() {
    return AuthEntity(
      userId: userId,
      email: email,
      role: _parseRole(role),
      token: token,
      refreshToken: refreshToken,
      createdAt: createdAt,
    );
  }

  /// Parse role string to UserRole enum
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'tutor':
        return UserRole.tutor;
      case 'student':
      default:
        return UserRole.student;
    }
  }
}

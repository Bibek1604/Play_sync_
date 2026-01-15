import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';

/// API Response model for authentication
class AuthResponseModel {
  final String? userId;
  final String? fullName;
  final String email;
  final String role;
  final String? token;
  final String? refreshToken;
  final String? message;
  final DateTime? createdAt;
  final bool? isVerified;

  AuthResponseModel({
    this.userId,
    this.fullName,
    required this.email,
    required this.role,
    this.token,
    this.refreshToken,
    this.message,
    this.createdAt,
    this.isVerified,
  });

  /// Parse from JSON response - handles nested 'data' or 'user' objects
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Check if response has nested data/user object
    final Map<String, dynamic> userData;
    if (json.containsKey('data') && json['data'] is Map) {
      userData = json['data'] as Map<String, dynamic>;
    } else if (json.containsKey('user') && json['user'] is Map) {
      userData = json['user'] as Map<String, dynamic>;
    } else {
      userData = json;
    }

    // Extract token from root or nested object
    final token = json['token'] ?? 
                  json['accessToken'] ?? 
                  json['access_token'] ??
                  userData['token'] ??
                  userData['accessToken'];
    
    final refreshToken = json['refreshToken'] ?? 
                         json['refresh_token'] ??
                         userData['refreshToken'] ??
                         userData['refresh_token'];

    return AuthResponseModel(
      userId: userData['_id'] ?? userData['userId'] ?? userData['id'],
      fullName: userData['fullName'] ?? userData['full_name'] ?? userData['name'],
      email: userData['email'] ?? json['email'] ?? '',
      role: userData['role'] ?? json['role'] ?? 'user',
      token: token,
      refreshToken: refreshToken,
      message: json['message'],
      createdAt: userData['createdAt'] != null
          ? DateTime.tryParse(userData['createdAt'].toString())
          : null,
      isVerified: userData['isVerified'] ?? false,
    );
  }

  /// Convert to Domain Entity
  AuthEntity toEntity() {
    return AuthEntity(
      userId: userId,
      fullName: fullName,
      email: email,
      role: _parseRole(role),
      token: token,
      refreshToken: refreshToken,
      createdAt: createdAt,
    );
  }

  /// Parse role string to UserRole enum
  /// Backend uses 'user' and 'admin' only
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.student;
    }
  }
}

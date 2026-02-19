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
  ///
  /// Login / refresh-token response shape:
  ///   { "success": true, "data": { "accessToken": "...", "refreshToken": "...",
  ///                                 "user": { "id": "...", "fullName": "...", ... } } }
  ///
  /// Register response shape:
  ///   { "success": true, "data": { "user": { "id": "...", "fullName": "...", ... } } }
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Step 1: unwrap the response envelope (always present in backend responses)
    final Map<String, dynamic> envelopeData;
    if (json.containsKey('data') && json['data'] is Map) {
      envelopeData = json['data'] as Map<String, dynamic>;
    } else {
      envelopeData = json;
    }

    // Step 2: drill into the nested 'user' object inside the envelope if it exists.
    // Login/refresh: envelopeData = { accessToken, refreshToken, user: {...} }
    // Register:      envelopeData = { user: {...} }
    // Older/flat:    envelopeData = { _id/id, fullName, email, ... }
    final Map<String, dynamic> userData;
    if (envelopeData.containsKey('user') && envelopeData['user'] is Map) {
      userData = envelopeData['user'] as Map<String, dynamic>;
    } else if (json.containsKey('user') && json['user'] is Map) {
      userData = json['user'] as Map<String, dynamic>;
    } else {
      userData = envelopeData;
    }

    // Step 3: tokens live in the envelope, not in the user sub-object
    final token = envelopeData['accessToken'] ??
                  envelopeData['token'] ??
                  envelopeData['access_token'] ??
                  json['accessToken'] ??
                  json['token'] ??
                  json['access_token'];

    final refreshTokenValue = envelopeData['refreshToken'] ??
                              envelopeData['refresh_token'] ??
                              json['refreshToken'] ??
                              json['refresh_token'];

    return AuthResponseModel(
      userId: userData['id']?.toString() ??
              userData['_id']?.toString() ??
              userData['userId']?.toString(),
      fullName: userData['fullName'] ?? userData['full_name'] ?? userData['name'],
      email: userData['email'] ?? json['email'] ?? '',
      role: userData['role'] ?? json['role'] ?? 'user',
      token: token,
      refreshToken: refreshTokenValue,
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
        return UserRole.user;
    }
  }
}

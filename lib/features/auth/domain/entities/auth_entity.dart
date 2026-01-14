import 'package:equatable/equatable.dart';

enum UserRole { student, admin, tutor }

/// Authentication Entity - Represents user data in domain layer
class AuthEntity extends Equatable {
  final String? userId;
  final String? fullName;
  final String email;
  final String? password; // Only used for registration, never stored
  final UserRole role;
  final String? token;
  final String? refreshToken;
  final DateTime? createdAt;

  const AuthEntity({
    this.userId,
    this.fullName,
    required this.email,
    this.password,
    this.role = UserRole.student,
    this.token,
    this.refreshToken,
    this.createdAt,
  });

  /// Copy with method for immutability
  AuthEntity copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? password,
    UserRole? role,
    String? token,
    String? refreshToken,
    DateTime? createdAt,
  }) {
    return AuthEntity(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [userId, fullName, email, role, token, refreshToken, createdAt];
}

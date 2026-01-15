import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';

/// Abstract repository interface for authentication operations
abstract interface class IAuthRepository {
  /// Register a new user
  Future<Either<Failure, AuthEntity>> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Login user with email and password
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  });

  /// Logout current user
  Future<Either<Failure, bool>> logout();

  /// Get current logged in user
  Future<Either<Failure, AuthEntity?>> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();
}

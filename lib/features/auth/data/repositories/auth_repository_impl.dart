import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/auth/data/datasources/auth_datasource.dart';
import 'package:play_sync_new/core/api/api_datasource_factory.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

/// Provider for authentication repository
/// Uses smart datasource that automatically switches between remote and local
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(secureStorage: secureStorage, ref: ref);
});

/// Repository implementation for authentication
class AuthRepository implements IAuthRepository {
  final FlutterSecureStorage _secureStorage;
  final Ref _ref;

  AuthRepository({
    required FlutterSecureStorage secureStorage,
    required Ref ref,
  })  : _secureStorage = secureStorage,
        _ref = ref;

  /// Get the appropriate datasource (smart switching)
  Future<IAuthDataSource> _getDataSource() async {
    return _ref.watch(smartAuthDataSourceProvider.future);
  }

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String fullName,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    try {
      final datasource = await _getDataSource();
      final response = await datasource.register(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      // Save token to secure storage
      await _secureStorage.write(key: 'access_token', value: response.token);
      await _secureStorage.write(key: 'refresh_token', value: response.refreshToken);
      await _secureStorage.write(key: 'user_id', value: response.userId);
      await _secureStorage.write(key: 'user_email', value: response.email);
      await _secureStorage.write(key: 'user_role', value: response.role);
      await _secureStorage.write(key: 'user_fullName', value: response.fullName);
      
      return Right(response.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: 'Registration failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final datasource = await _getDataSource();
      final response = await datasource.login(
        email: email,
        password: password,
      );
      
      // Save token to secure storage
      await _secureStorage.write(key: 'access_token', value: response.token);
      await _secureStorage.write(key: 'refresh_token', value: response.refreshToken);
      await _secureStorage.write(key: 'user_id', value: response.userId);
      await _secureStorage.write(key: 'user_email', value: response.email);
      await _secureStorage.write(key: 'user_role', value: response.role);
      
      return Right(response.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: 'Login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final datasource = await _getDataSource();
      await datasource.logout();
      
      // Clear secure storage
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.delete(key: 'user_role');
      
      return const Right(true);
    } catch (e) {
      return Left(AuthFailure(message: 'Logout failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity?>> getCurrentUser() async {
    try {
      final userId = await _secureStorage.read(key: 'user_id');
      final email = await _secureStorage.read(key: 'user_email');
      final role = await _secureStorage.read(key: 'user_role');
      final token = await _secureStorage.read(key: 'access_token');

      if (email == null || token == null) {
        return const Right(null);
      }

      return Right(AuthEntity(
        userId: userId,
        email: email,
        role: _parseRole(role ?? 'student'),
        token: token,
      ));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to get user: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null;
  }

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

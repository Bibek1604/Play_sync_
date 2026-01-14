import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/auth/data/datasources/auth_datasource.dart';
import 'package:play_sync_new/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final remoteDatasource = ref.read(authRemoteDatasourceProvider);
  return AuthRepository(remoteDatasource: remoteDatasource);
});

/// Repository implementation for authentication
class AuthRepository implements IAuthRepository {
  final IAuthDataSource _remoteDatasource;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository({required IAuthDataSource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, AuthEntity>> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.register(
        email: email,
        password: password,
      );
      return Right(response.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> registerAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.registerAdmin(
        email: email,
        password: password,
      );
      return Right(response.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> registerTutor({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.registerTutor(
        email: email,
        password: password,
      );
      return Right(response.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.login(
        email: email,
        password: password,
      );
      return Right(response.toEntity());
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await _remoteDatasource.logout();
      return Right(result);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
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
      return Left(AuthFailure(message: e.toString()));
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
      case 'tutor':
        return UserRole.tutor;
      default:
        return UserRole.student;
    }
  }
}

  AuthRepositoryImpl({
    required this.localDatasource,
    // required this.remoteDatasource,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      // Validate against registered users
      final user = await localDatasource.validateLogin(email, password);
      
      if (user == null) {
        // Check if email exists to give better error message
        final isRegistered = await localDatasource.isEmailRegistered(email);
        if (!isRegistered) {
          return Left(AuthFailure('Email not registered. Please sign up first.'));
        }
        return Left(AuthFailure('Invalid password. Please try again.'));
      }
      
      // Cache the logged-in user
      await localDatasource.cacheUser(user);
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure('Login failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> signup(String email, String password, {String? name}) async {
    try {
      // Check if email already registered
      final isRegistered = await localDatasource.isEmailRegistered(email);
      if (isRegistered) {
        return Left(AuthFailure('Email already registered. Please login instead.'));
      }
      
      // Register the user
      await localDatasource.registerUser(email, password, name);
      
      // Return user info (but don't cache - they must login)
      final user = UserModel(
        id: email.hashCode.toString(),
        email: email.toLowerCase().trim(),
        name: name,
        token: '', // Empty token - user gets real token on login
      );
      return Right(user.toEntity());
    } catch (e) {
      return Left(AuthFailure('Signup failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCachedUser() async {
    try {
      final user = await localDatasource.getCachedUser();
      return Right(user?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Failed to get cached user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDatasource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Logout failed: ${e.toString()}'));
    }
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource localDatasource;
  // final AuthRemoteDatasource remoteDatasource; // For future use

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

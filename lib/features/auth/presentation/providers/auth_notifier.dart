import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/signup.dart';
import '../../domain/usecases/get_cached_user.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

/// Auth state that holds the current user and loading/error states
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// AuthNotifier manages authentication state using clean architecture
class AuthNotifier extends StateNotifier<AuthState> {
  final Login _login;
  final Signup _signup;
  final GetCachedUser _getCachedUser;
  final Logout _logout;

  AuthNotifier({
    required Login login,
    required Signup signup,
    required GetCachedUser getCachedUser,
    required Logout logout,
  })  : _login = login,
        _signup = signup,
        _getCachedUser = getCachedUser,
        _logout = logout,
        super(const AuthState(isLoading: true)) {
    _init();
  }

  /// Initialize - check for cached user on startup
  Future<void> _init() async {
    final result = await _getCachedUser();
    result.fold(
      (failure) => state = const AuthState(),
      (user) => state = AuthState(user: user),
    );
  }

  /// Login with email and password
  Future<Either<Failure, User>> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _login(email, password);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return Left(failure);
      },
      (user) {
        state = AuthState(user: user);
        return Right(user);
      },
    );
  }

  /// Signup with email, password and optional name
  /// Note: This creates the user but does NOT auto-login
  /// User must login separately after registration
  Future<Either<Failure, User>> signup(String email, String password, {String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _signup(email, password, name: name);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return Left(failure);
      },
      (user) {
        // Don't set user in state - user needs to login after registration
        state = state.copyWith(isLoading: false, clearError: true);
        return Right(user);
      },
    );
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _logout();
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = const AuthState(),
    );
  }
}

// ============================================================================
// DEPENDENCY INJECTION PROVIDERS
// ============================================================================

/// Repository provider - injects local datasource
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localDatasource = AuthLocalDatasourceImpl();
  return AuthRepositoryImpl(localDatasource: localDatasource);
});

/// Use case providers
final loginUseCaseProvider = Provider<Login>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return Login(repo);
});

final signupUseCaseProvider = Provider<Signup>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return Signup(repo);
});

final getCachedUserUseCaseProvider = Provider<GetCachedUser>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return GetCachedUser(repo);
});

final logoutUseCaseProvider = Provider<Logout>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return Logout(repo);
});

/// Main auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    login: ref.read(loginUseCaseProvider),
    signup: ref.read(signupUseCaseProvider),
    getCachedUser: ref.read(getCachedUserUseCaseProvider),
    logout: ref.read(logoutUseCaseProvider),
  );
});


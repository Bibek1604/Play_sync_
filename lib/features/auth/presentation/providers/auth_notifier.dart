import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/usecases/login_usecase.dart';
import 'package:play_sync_new/features/auth/domain/usecases/register_usecase.dart';

// ============================================================================
// AUTH STATE
// ============================================================================

/// Enum for authentication status
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state that holds the current user and status
class AuthState {
  final AuthEntity? user;
  final AuthStatus status;
  final String? error;

  const AuthState({
    this.user,
    this.status = AuthStatus.initial,
    this.error,
  });

  AuthState copyWith({
    AuthEntity? user,
    AuthStatus? status,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;

  static AuthState authenticated({required AuthEntity user}) {
    return AuthState(user: user, status: AuthStatus.authenticated);
  }
}

// ============================================================================
// AUTH NOTIFIER
// ============================================================================

/// AuthNotifier manages authentication state using clean architecture
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUsecase _loginUsecase;
  final RegisterUsecase _registerUsecase;
  final Ref _ref;

  AuthNotifier({
    required LoginUsecase loginUsecase,
    required RegisterUsecase registerUsecase,
    required Ref ref,
  })  : _loginUsecase = loginUsecase,
        _registerUsecase = registerUsecase,
        _ref = ref,
        super(const AuthState()) {
    _init();
  }

  /// Initialize - check for cached user on startup
  Future<void> _init() async {
    final repository = _ref.read(authRepositoryProvider);
    final isLoggedIn = await repository.isLoggedIn();
    
    if (isLoggedIn) {
      final result = await repository.getCurrentUser();
      result.fold(
        (failure) => state = const AuthState(status: AuthStatus.unauthenticated),
        (user) {
          if (user != null) {
            state = AuthState(user: user, status: AuthStatus.authenticated);
          } else {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        },
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with email and password
  Future<Either<Failure, AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    
    final result = await _loginUsecase(LoginParams(
      email: email,
      password: password,
    ));
    
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, error: failure.message);
        return Left(failure);
      },
      (user) {
        state = AuthState(user: user, status: AuthStatus.authenticated);
        return Right(user);
      },
    );
  }

  /// Register user
  Future<Either<Failure, AuthEntity>> register({
    required String fullName,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    
    final result = await _registerUsecase(RegisterParams(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    ));
    
    return result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, error: failure.message);
        return Left(failure);
      },
      (user) {
        // After registration, set state but don't auto-login
        state = state.copyWith(status: AuthStatus.unauthenticated, clearError: true);
        return Right(user);
      },
    );
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.logout();
    
    result.fold(
      (failure) => state = state.copyWith(status: AuthStatus.error, error: failure.message),
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
    );
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Main auth state provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUsecase: ref.read(loginUsecaseProvider),
    registerUsecase: ref.read(registerUsecaseProvider),
    ref: ref,
  );
});


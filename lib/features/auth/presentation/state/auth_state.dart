import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_entity.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthEntity? user;
  final String? error;
  final String? token;
  final String? refreshToken;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.token,
    this.refreshToken,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    AuthEntity? user,
    String? error,
    String? token,
    String? refreshToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  List<Object?> get props => [status, user, error, token, refreshToken];
}

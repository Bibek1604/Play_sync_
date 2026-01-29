import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
// import '../../domain/usecases/register_admin_usecase.dart';
// import '../../domain/usecases/register_tutor_usecase.dart';
import '../state/auth_state.dart';

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(() => AuthViewModel());

class AuthViewModel extends Notifier<AuthState> {
  late LoginUsecase _loginUsecase;
  late RegisterUsecase _registerUsecase;
//   late RegisterAdminUsecase _registerAdminUsecase;
//   late RegisterTutorUsecase _registerTutorUsecase;

  @override
  AuthState build() {
    _loginUsecase = ref.watch(loginUsecaseProvider);
    _registerUsecase = ref.watch(registerUsecaseProvider);
//     _registerAdminUsecase = ref.watch(registerAdminUsecaseProvider);
//     _registerTutorUsecase = ref.watch(registerTutorUsecaseProvider);

    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _loginUsecase.call(
      LoginParams(email: email, password: password),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> register(String fullName, String email, String password, {String? confirmPassword}) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerUsecase.call(
      RegisterParams(
        fullName: fullName, 
        email: email, 
        password: password,
        confirmPassword: confirmPassword,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

/*
  Future<void> registerAdmin(String fullName, String email, String password, {String? adminCode}) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerAdminUsecase.call(
      RegisterAdminParams(fullName: fullName, email: email, password: password, adminCode: adminCode),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> registerTutor(String fullName, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _registerTutorUsecase.call(
      RegisterTutorParams(fullName: fullName, email: email, password: password),
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        error: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }
*/

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    // Call logout use case when available
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      token: null,
      refreshToken: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

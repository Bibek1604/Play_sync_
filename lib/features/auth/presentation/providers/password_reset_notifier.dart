import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/forgot_password_entity.dart';
import '../../domain/usecases/password_reset_usecases.dart';

/// State for password reset operations
class PasswordResetState {
  final bool isLoading;
  final bool isSuccess;
  final String? message;
  final Failure? failure;
  final int? remainingTime; // For OTP expiry countdown

  PasswordResetState({
    this.isLoading = false,
    this.isSuccess = false,
    this.message,
    this.failure,
    this.remainingTime,
  });

  PasswordResetState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? message,
    Failure? failure,
    int? remainingTime,
  }) {
    return PasswordResetState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      message: message ?? this.message,
      failure: failure ?? this.failure,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }

  PasswordResetState reset() {
    return PasswordResetState();
  }
}

/// State notifier for password reset operations
class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  PasswordResetNotifier({
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.verifyOtpUseCase,
  }) : super(PasswordResetState());

  /// Send OTP to user's email
  Future<void> sendPasswordResetOtp(String email) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await forgotPasswordUseCase(email);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
          isSuccess: false,
        );
      },
      (response) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: response.success,
          message: response.message,
          failure: null,
        );
      },
    );
  }

  /// Reset password with OTP
  Future<void> resetPassword(ResetPasswordRequest request) async {
    state = state.copyWith(isLoading: true, failure: null);

    final result = await resetPasswordUseCase(request);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          failure: failure,
          isSuccess: false,
        );
      },
      (response) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: response.success,
          message: response.message,
          failure: null,
        );
      },
    );
  }

  /// Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    final result = await verifyOtpUseCase(VerifyOtpParams(email: email, otp: otp));

    return result.fold(
      (failure) => false,
      (isValid) => isValid,
    );
  }

  /// Reset state
  void reset() {
    state = PasswordResetState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(failure: null);
  }
}

// Riverpod providers would be defined in your DI/service locator setup

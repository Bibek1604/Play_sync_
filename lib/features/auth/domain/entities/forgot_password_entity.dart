import 'package:equatable/equatable.dart';

/// Forgot Password Request Entity
/// Represents the data needed to initiate password reset
class ForgotPasswordRequest extends Equatable {
  final String email;

  const ForgotPasswordRequest({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}

/// Password Reset OTP Verification Entity
/// Represents the data needed to verify OTP and reset password
class ResetPasswordRequest extends Equatable {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, otp, newPassword, confirmPassword];
}

/// Password Reset Response Entity
class PasswordResetResponse extends Equatable {
  final bool success;
  final String message;

  const PasswordResetResponse({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}

/// Forgot Password OTP Response Entity
class ForgotPasswordResponse extends Equatable {
  final bool success;
  final String message;

  const ForgotPasswordResponse({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];
}

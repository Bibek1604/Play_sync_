import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/forgot_password_entity.dart';
import '../repositories/password_reset_repository.dart';

/// UseCase for requesting password reset OTP
/// 
/// This use case handles the first step of password reset:
/// - Accepts email address
/// - Calls repository to send OTP to email
/// - Returns success or failure
class ForgotPasswordUseCase implements UseCase<ForgotPasswordResponse, String> {
  final PasswordResetRepository repository;

  ForgotPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, ForgotPasswordResponse>> call(String email) async {
    return await repository.forgotPassword(email);
  }
}

/// UseCase for resetting password with OTP
/// 
/// This use case handles the second step of password reset:
/// - Accepts email, OTP, and new password
/// - Validates inputs
/// - Calls repository to reset password
/// - Returns success or failure
class ResetPasswordUseCase implements UseCase<PasswordResetResponse, ResetPasswordRequest> {
  final PasswordResetRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, PasswordResetResponse>> call(ResetPasswordRequest request) async {
    return await repository.resetPassword(request);
  }
}

/// UseCase for verifying OTP validity
/// 
/// This use case provides real-time OTP verification
/// - Accepts email and OTP
/// - Calls repository to verify OTP
/// - Returns validity status
class VerifyOtpUseCase implements UseCase<bool, VerifyOtpParams> {
  final PasswordResetRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(params.email, params.otp);
  }
}

/// Parameters for OTP verification
class VerifyOtpParams {
  final String email;
  final String otp;

  VerifyOtpParams({
    required this.email,
    required this.otp,
  });
}

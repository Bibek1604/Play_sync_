import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/forgot_password_entity.dart';

/// Abstract repository for password reset operations
/// Defines contract for implementing password reset functionality
abstract class PasswordResetRepository {
  /// Send OTP to user's email for password reset
  /// 
  /// Parameters:
  ///   - email: User's registered email address
  /// 
  /// Returns:
  ///   - Right: ForgotPasswordResponse on success
  ///   - Left: Failure on error
  Future<Either<Failure, ForgotPasswordResponse>> forgotPassword(
    String email,
  );

  /// Reset password using OTP
  /// 
  /// Parameters:
  ///   - request: ResetPasswordRequest containing email, OTP, and new passwords
  /// 
  /// Returns:
  ///   - Right: PasswordResetResponse on success
  ///   - Left: Failure on error
  Future<Either<Failure, PasswordResetResponse>> resetPassword(
    ResetPasswordRequest request,
  );

  /// Verify OTP validity (optional, for real-time validation)
  /// 
  /// Parameters:
  ///   - email: User's email
  ///   - otp: OTP to verify
  /// 
  /// Returns:
  ///   - Right: bool indicating if OTP is valid
  ///   - Left: Failure on error
  Future<Either<Failure, bool>> verifyOtp(String email, String otp);
}

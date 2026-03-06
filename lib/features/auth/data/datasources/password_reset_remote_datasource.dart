import 'package:dio/dio.dart';
import '../models/forgot_password_model.dart';
import '../../../../core/api/api_endpoints.dart';

/// Abstract data source for password reset remote operations
abstract class PasswordResetRemoteDataSource {
  /// Send OTP to user's email
  Future<ForgotPasswordResponseDto> forgotPassword(String email);

  /// Reset password with OTP
  Future<ResetPasswordResponseDto> resetPassword(ResetPasswordDto dto);

  /// Verify OTP
  Future<bool> verifyOtp(String email, String otp);
}

/// Implementation of PasswordResetRemoteDataSource using Dio
class PasswordResetRemoteDataSourceImpl implements PasswordResetRemoteDataSource {
  final Dio dio;

  PasswordResetRemoteDataSourceImpl({required this.dio});

  @override
  Future<ForgotPasswordResponseDto> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ForgotPasswordResponseDto.fromJson(
          response.data['data'] ?? response.data,
        );
      }

      throw Exception('Failed to send OTP to email');
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<ResetPasswordResponseDto> resetPassword(ResetPasswordDto dto) async {
    try {
      final response = await dio.post(
        ApiEndpoints.resetPassword,
        data: dto.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ResetPasswordResponseDto.fromJson(
          response.data['data'] ?? response.data,
        );
      }

      throw Exception('Failed to reset password');
    } on DioException catch (e) {
      _handleDioException(e);
      rethrow;
    }
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await dio.post(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['valid'] ?? false;
      }

      return false;
    } on DioException catch (e) {
      _handleDioException(e);
      return false;
    }
  }

  /// Handle Dio exceptions and provide meaningful error messages
  void _handleDioException(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Server response timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        // Always prefer the backend\'s own message over hardcoded strings
        final backendMsg =
            e.response?.data is Map ? e.response?.data['message'] as String? : null;
        final statusCode = e.response?.statusCode;
        if (backendMsg != null && backendMsg.isNotEmpty) {
          message = backendMsg;
        } else if (statusCode == 429) {
          message = 'Too many attempts. Please try again later.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'An error occurred. Please try again.';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled';
        break;
      case DioExceptionType.unknown:
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = 'An unexpected error occurred';
    }

    throw Exception(message);
  }
}

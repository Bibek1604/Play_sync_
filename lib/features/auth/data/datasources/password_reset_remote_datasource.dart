import 'package:dio/dio.dart';
import '../models/forgot_password_model.dart';

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
  static const String baseUrl = 'api/v1/auth';

  PasswordResetRemoteDataSourceImpl({required this.dio});

  @override
  Future<ForgotPasswordResponseDto> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        '$baseUrl/forgot-password',
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
        '$baseUrl/reset-password',
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
        '$baseUrl/verify-otp',
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
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          message = 'Email not found in our system.';
        } else if (statusCode == 429) {
          message = 'Too many attempts. Please try again later.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = e.response?.data['message'] ?? 'An error occurred';
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

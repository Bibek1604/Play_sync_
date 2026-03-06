import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/forgot_password_entity.dart';

part 'forgot_password_model.g.dart';

/// DTO for Forgot Password Request
@JsonSerializable()
class ForgotPasswordDto {
  final String email;

  ForgotPasswordDto({required this.email});

  factory ForgotPasswordDto.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ForgotPasswordDtoToJson(this);

  /// Convert to domain entity
  String toDomain() => email;
}

/// DTO for Reset Password Request
@JsonSerializable()
class ResetPasswordDto {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordDto({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  factory ResetPasswordDto.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordDtoToJson(this);

  /// Convert to domain entity
  ResetPasswordRequest toDomain() => ResetPasswordRequest(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
}

/// DTO for Forgot Password Response
@JsonSerializable()
class ForgotPasswordResponseDto {
  final bool success;
  final String message;

  ForgotPasswordResponseDto({
    required this.success,
    required this.message,
  });

  factory ForgotPasswordResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ForgotPasswordResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ForgotPasswordResponseDtoToJson(this);

  /// Convert to domain entity
  ForgotPasswordResponse toDomain() => ForgotPasswordResponse(
        success: success,
        message: message,
      );
}

/// DTO for Reset Password Response
@JsonSerializable()
class ResetPasswordResponseDto {
  final bool success;
  final String message;

  ResetPasswordResponseDto({
    required this.success,
    required this.message,
  });

  factory ResetPasswordResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ResetPasswordResponseDtoToJson(this);

  /// Convert to domain entity
  PasswordResetResponse toDomain() => PasswordResetResponse(
        success: success,
        message: message,
      );
}

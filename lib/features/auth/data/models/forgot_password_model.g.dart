// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forgot_password_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForgotPasswordDto _$ForgotPasswordDtoFromJson(Map<String, dynamic> json) =>
    ForgotPasswordDto(
      email: json['email'] as String,
    );

Map<String, dynamic> _$ForgotPasswordDtoToJson(ForgotPasswordDto instance) =>
    <String, dynamic>{
      'email': instance.email,
    };

ResetPasswordDto _$ResetPasswordDtoFromJson(Map<String, dynamic> json) =>
    ResetPasswordDto(
      email: json['email'] as String,
      otp: json['otp'] as String,
      newPassword: json['newPassword'] as String,
      confirmPassword: json['confirmPassword'] as String,
    );

Map<String, dynamic> _$ResetPasswordDtoToJson(ResetPasswordDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'otp': instance.otp,
      'newPassword': instance.newPassword,
      'confirmPassword': instance.confirmPassword,
    };

ForgotPasswordResponseDto _$ForgotPasswordResponseDtoFromJson(
        Map<String, dynamic> json) =>
    ForgotPasswordResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ForgotPasswordResponseDtoToJson(
        ForgotPasswordResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

ResetPasswordResponseDto _$ResetPasswordResponseDtoFromJson(
        Map<String, dynamic> json) =>
    ResetPasswordResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$ResetPasswordResponseDtoToJson(
        ResetPasswordResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
    };

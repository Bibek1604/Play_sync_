import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/forgot_password_entity.dart';
import '../../domain/repositories/password_reset_repository.dart';
import '../datasources/password_reset_remote_datasource.dart';
import '../models/forgot_password_model.dart';

/// Implementation of PasswordResetRepository
/// Handles all password reset related operations
class PasswordResetRepositoryImpl implements PasswordResetRepository {
  final PasswordResetRemoteDataSource remoteDataSource;

  PasswordResetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ForgotPasswordResponse>> forgotPassword(
    String email,
  ) async {
    try {
      final result = await remoteDataSource.forgotPassword(email);
      return Right(result.toDomain());
    } on Exception catch (e) {
      return Left(
        ServerFailure(
          message: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PasswordResetResponse>> resetPassword(
    ResetPasswordRequest request,
  ) async {
    try {
      final dto = ResetPasswordDto(
        email: request.email,
        otp: request.otp,
        newPassword: request.newPassword,
        confirmPassword: request.confirmPassword,
      );

      final result = await remoteDataSource.resetPassword(dto);
      return Right(result.toDomain());
    } on Exception catch (e) {
      return Left(
        ServerFailure(
          message: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(String email, String otp) async {
    try {
      final result = await remoteDataSource.verifyOtp(email, otp);
      return Right(result);
    } on Exception catch (e) {
      return Left(
        ServerFailure(
          message: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}

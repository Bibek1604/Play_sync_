import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return RegisterUsecase(repository: repository);
});

class RegisterParams {
  final String fullName;
  final String email;
  final String password;
  final String? confirmPassword;

  RegisterParams({
    required this.fullName,
    required this.email,
    required this.password,
    this.confirmPassword,
  });
}

class RegisterUsecase implements UsecaseWithParams<AuthEntity, RegisterParams> {
  final IAuthRepository _repository;

  RegisterUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, AuthEntity>> call(RegisterParams params) {
    return _repository.register(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      confirmPassword: params.confirmPassword,
    );
  }
}

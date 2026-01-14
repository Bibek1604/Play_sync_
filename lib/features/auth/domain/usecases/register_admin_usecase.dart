import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final registerAdminUsecaseProvider = Provider<RegisterAdminUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return RegisterAdminUsecase(repository: repository);
});

class RegisterAdminParams {
  final String fullName;
  final String email;
  final String password;
  final String? adminCode;

  RegisterAdminParams({
    required this.fullName,
    required this.email,
    required this.password,
    this.adminCode,
  });
}

class RegisterAdminUsecase
    implements UsecaseWithParams<AuthEntity, RegisterAdminParams> {
  final IAuthRepository _repository;

  RegisterAdminUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, AuthEntity>> call(RegisterAdminParams params) {
    return _repository.registerAdmin(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
      adminCode: params.adminCode,
    );
  }
}

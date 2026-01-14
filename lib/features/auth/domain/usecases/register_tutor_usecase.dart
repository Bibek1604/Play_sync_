import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:play_sync_new/features/auth/domain/entities/auth_entity.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';

final registerTutorUsecaseProvider = Provider<RegisterTutorUsecase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return RegisterTutorUsecase(repository: repository);
});

class RegisterTutorParams {
  final String fullName;
  final String email;
  final String password;

  RegisterTutorParams({
    required this.fullName,
    required this.email,
    required this.password,
  });
}

class RegisterTutorUsecase
    implements UsecaseWithParams<AuthEntity, RegisterTutorParams> {
  final IAuthRepository _repository;

  RegisterTutorUsecase({required IAuthRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, AuthEntity>> call(RegisterTutorParams params) {
    return _repository.registerTutor(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
    );
  }
}

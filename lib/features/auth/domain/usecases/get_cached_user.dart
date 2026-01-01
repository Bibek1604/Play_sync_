import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCachedUser {
  final AuthRepository repository;
  GetCachedUser(this.repository);

  Future<Either<Failure, User?>> call() {
    return repository.getCachedUser();
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Signup {
  final AuthRepository repository;
  Signup(this.repository);

  Future<Either<Failure, User>> call(String email, String password, {String? name}) {
    return repository.signup(email, password, name: name);
  }
}

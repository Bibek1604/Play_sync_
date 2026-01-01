import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> signup(String email, String password, {String? name});
  Future<Either<Failure, User?>> getCachedUser();
  Future<Either<Failure, void>> logout();
}

import 'package:fpdart/fpdart.dart';
import '../error/failure.dart';

/// Base class for all use cases in the application
/// Follows Clean Architecture principles
/// Type Parameters:
/// - [Type]: The return type of the use case
/// - [Params]: The parameters required by the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case with given parameters
  Future<Either<Failure, Type>> call(Params params);
}

/// Special class for use cases that don't require parameters
class NoParams {
  const NoParams();
}

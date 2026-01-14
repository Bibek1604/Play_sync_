import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';

/// Base interface for use cases that require parameters
///
/// [SuccessType] - The type of successful result
/// [Params] - The type of parameters required for the use case
///
/// Example:
/// ```dart
/// class GetProductByIdUsecase implements UsecaseWithParams<ProductEntity, GetProductParams> {
///   @override
///   Future<Either<Failure, ProductEntity>> call(GetProductParams params) async {
///     // Implementation
///   }
/// }
/// ```
abstract interface class UsecaseWithParams<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

/// Base interface for use cases that don't require parameters
///
/// [SuccessType] - The type of successful result
///
/// Example:
/// ```dart
/// class GetAllProductsUsecase implements UsecaseWithoutParams<List<ProductEntity>> {
///   @override
///   Future<Either<Failure, List<ProductEntity>>> call() async {
///     // Implementation
///   }
/// }
/// ```
abstract interface class UsecaseWithoutParams<SuccessType> {
  Future<Either<Failure, SuccessType>> call();
}

import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Failure for local database operations
class LocalDatabaseFailure extends Failure {
  const LocalDatabaseFailure({
    String message = "Local Database Failure",
  }) : super(message);
}

/// Failure for API/remote server operations
class ApiFailure extends Failure {
  final int? statusCode;

  const ApiFailure({
    String message = "API Failure",
    this.statusCode,
  }) : super(message);

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Failure for network connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = "Network Error - No internet connection",
  }) : super(message);
}

/// Failure for authentication/authorization issues
class AuthFailure extends Failure {
  const AuthFailure({
    String message = "Authentication Failed",
  }) : super(message);
}

/// Failure for cache-related operations
class CacheFailure extends Failure {
  const CacheFailure({
    String message = "Cache Failure",
  }) : super(message);
}

/// Failure for general/unknown errors
class GeneralFailure extends Failure {
  const GeneralFailure({
    String message = "An unexpected error occurred",
  }) : super(message);
}

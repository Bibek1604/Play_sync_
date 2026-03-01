import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Used with Either type for functional error handling
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server-related failures (5xx errors)
class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Server error occurred',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Network/Connection failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Client-side failures (4xx errors)
class ClientFailure extends Failure {
  const ClientFailure({
    String message = 'Invalid request',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Authentication failures (401, 403)
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    String message = 'Authentication failed',
    int? statusCode = 401,
  }) : super(message: message, statusCode: statusCode);
}

/// Validation failures (400)
class ValidationFailure extends Failure {
  const ValidationFailure({
    String message = 'Validation failed',
    int? statusCode = 400,
  }) : super(message: message, statusCode: statusCode);
}

/// Not Found failures (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = 'Resource not found',
    int? statusCode = 404,
  }) : super(message: message, statusCode: statusCode);
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    String message = 'Request timeout',
    int? statusCode = 408,
  }) : super(message: message, statusCode: statusCode);
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Cache error occurred',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Unknown/Unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    String message = 'An unexpected error occurred',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

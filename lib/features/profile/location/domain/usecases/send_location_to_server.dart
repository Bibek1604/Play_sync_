import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../../../../../core/error/failures.dart';

/// Use case for sending location data to backend server
/// 
/// This encapsulates the business logic for:
/// 1. Validating location data
/// 2. Sending to API endpoint
/// 3. Handling network errors
/// 4. Handling API errors
class SendLocationToServer {
  final LocationRepository repository;

  SendLocationToServer(this.repository);

  /// Execute the use case to send location to server
  /// 
  /// [location] - LocationEntity with GPS coordinates and address
  /// 
  /// Returns:
  /// - Right(void) on success
  /// - Left(Failure) on error
  /// 
  /// Possible failures:
  /// - NetworkFailure: No internet connection
  /// - ServerFailure: API error (4xx, 5xx)
  /// - ValidationFailure: Invalid location data
  Future<Either<Failure, void>> call(LocationEntity location) async {
    // Validate location data
    if (!_isValidLocation(location)) {
      return Left(ValidationFailure(
        'Invalid location data. Latitude must be between -90 and 90, longitude between -180 and 180.',
      ));
    }

    // Send to server
    return repository.sendLocationToServer(location);
  }

  /// Validate location coordinates
  bool _isValidLocation(LocationEntity location) {
    final validLatitude = location.latitude >= -90 && location.latitude <= 90;
    final validLongitude = location.longitude >= -180 && location.longitude <= 180;
    final hasAddress = location.address.trim().isNotEmpty;

    return validLatitude && validLongitude && hasAddress;
  }

  /// Execute with retry logic
  /// 
  /// [location] - Location to send
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [retryDelay] - Delay between retries (default: 2 seconds)
  Future<Either<Failure, void>> executeWithRetry(
    LocationEntity location, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      final result = await call(location);
      
      if (result.isRight()) {
        return result;
      }

      attempts++;
      
      if (attempts < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }

    return Left(NetworkFailure(
      message: 'Failed to send location after multiple attempts. Please check your internet connection.',
    ));
  }
}

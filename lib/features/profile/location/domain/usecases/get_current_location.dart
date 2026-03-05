import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../repositories/location_repository.dart';
import '../../../../../core/error/failures.dart';

/// Use case for getting current GPS location
/// 
/// This encapsulates the business logic for:
/// 1. Checking location permissions
/// 2. Checking if GPS is enabled
/// 3. Getting current coordinates
/// 4. Converting coordinates to address
/// 5. Creating LocationEntity with all data
class GetCurrentLocation {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  /// Execute the use case to get current location
  /// 
  /// Returns [LocationEntity] with GPS coordinates and human-readable address
  /// 
  /// This method handles:
  /// - Permission checks
  /// - GPS enabled checks
  /// - Coordinate fetching
  /// - Address reverse geocoding
  /// - Error handling for all steps
  Future<Either<Failure, LocationEntity>> call() async {
    // Step 1: Check if location permission is granted
    final permissionResult = await repository.requestLocationPermission();
    
    return permissionResult.fold(
      (failure) => Left(failure),
      (isGranted) async {
        if (!isGranted) {
          return Left(PermissionFailure(
            'Location permission is required to access your current location. Please grant permission in app settings.',
          ));
        }

        // Step 2: Check if GPS/location services are enabled
        final serviceResult = await repository.isLocationServiceEnabled();
        
        return serviceResult.fold(
          (failure) => Left(failure),
          (isEnabled) async {
            if (!isEnabled) {
              return Left(LocationServiceFailure(
                'Location services are disabled. Please enable GPS in your device settings.',
              ));
            }

            // Step 3: Get current GPS location
            final locationResult = await repository.getCurrentLocation();
            
            return locationResult;
          },
        );
      },
    );
  }

  /// Execute with custom error handling
  /// 
  /// Allows caller to handle specific error cases
  Future<Either<Failure, LocationEntity>> execute({
    bool skipPermissionCheck = false,
    bool skipServiceCheck = false,
  }) async {
    if (skipPermissionCheck && skipServiceCheck) {
      return repository.getCurrentLocation();
    }

    return call();
  }
}

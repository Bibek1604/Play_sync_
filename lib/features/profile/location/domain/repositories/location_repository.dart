import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../../../../../core/error/failures.dart';

/// Repository interface for location operations
/// 
/// This follows the Repository pattern and defines contracts for:
/// - Getting current GPS location
/// - Converting coordinates to addresses
/// - Sending location data to server
abstract class LocationRepository {
  /// Get current device GPS location with high accuracy
  /// 
  /// Returns [LocationEntity] on success or [Failure] on error.
  /// Possible failures:
  /// - PermissionFailure: Location permissions not granted
  /// - LocationServiceFailure: GPS is disabled
  /// - TimeoutFailure: Failed to get location within timeout
  Future<Either<Failure, LocationEntity>> getCurrentLocation();

  /// Convert GPS coordinates to human-readable address
  /// 
  /// Returns address string like "Butwal, Lumbini Province, Nepal"
  /// 
  /// [latitude] - GPS latitude coordinate
  /// [longitude] - GPS longitude coordinate
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });

  /// Send location data to backend server
  /// 
  /// Updates user's location on the server for:
  /// - Profile location
  /// - Offline game creation
  /// - Nearby game searches
  /// 
  /// [location] - Location entity with coordinates and address
  Future<Either<Failure, void>> sendLocationToServer(LocationEntity location);

  /// Request location permission from user
  /// 
  /// Returns:
  /// - true if permission granted
  /// - false if denied or permanently denied
  Future<Either<Failure, bool>> requestLocationPermission();

  /// Check if location services (GPS) are enabled
  /// 
  /// Returns:
  /// - true if GPS is enabled
  /// - false if GPS is disabled
  Future<Either<Failure, bool>> isLocationServiceEnabled();

  /// Open app settings for user to manually grant permissions
  /// 
  /// Used when permission is permanently denied
  Future<Either<Failure, bool>> openAppSettings();
}

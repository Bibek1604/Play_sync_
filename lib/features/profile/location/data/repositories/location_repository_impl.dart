import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';
import '../models/location_model.dart';
import '../../../../../core/error/failures.dart';

/// Implementation of LocationRepository
/// 
/// This class implements the repository interface and handles:
/// - Data source coordination
/// - Error handling and mapping to Failures
/// - Business logic validation
class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;

  LocationRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async {
    try {
      // Get location with address from data source
      final locationModel = await dataSource.getCurrentLocationWithAddress();

      // Convert model to entity
      return Right(locationModel.toEntity());
    } on LocationServiceDisabledException {
      return Left(LocationServiceFailure(
        'Location services are disabled. Please enable GPS in your device settings.',
      ));
    } on PermissionDeniedException {
      return Left(PermissionFailure(
        'Location permission denied. Please grant location access in app settings.',
      ));
    } catch (e) {
      return Left(GeneralFailure(
        message: 'Failed to get location: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final address = await dataSource.getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      return Right(address);
    } catch (e) {
      return Left(GeneralFailure(
        message: 'Failed to get address: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> sendLocationToServer(
    LocationEntity location,
  ) async {
    try {
      // Convert entity to model
      final locationModel = LocationModel.fromEntity(location);

      // Send to server
      await dataSource.sendLocationToServer(locationModel);

      return const Right(null);
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('socket')) {
        return Left(NetworkFailure(
          message: 'No internet connection. Please check your network.',
        ));
      } else if (errorMessage.contains('server error') ||
          errorMessage.contains('404') ||
          errorMessage.contains('500')) {
        return Left(ServerFailure(
          message: 'Server error: ${e.toString()}',
        ));
      } else {
        return Left(GeneralFailure(
          message: 'Failed to send location: ${e.toString()}',
        ));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> requestLocationPermission() async {
    try {
      final isGranted = await dataSource.requestLocationPermission();
      return Right(isGranted);
    } catch (e) {
      return Left(PermissionFailure(
        'Failed to request permission: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isLocationServiceEnabled() async {
    try {
      final isEnabled = await dataSource.isLocationServiceEnabled();
      return Right(isEnabled);
    } catch (e) {
      return Left(LocationServiceFailure(
        'Failed to check location service: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final opened = await dataSource.openAppSettings();
      return Right(opened);
    } catch (e) {
      return Left(GeneralFailure(
        message: 'Failed to open settings: ${e.toString()}',
      ));
    }
  }
}

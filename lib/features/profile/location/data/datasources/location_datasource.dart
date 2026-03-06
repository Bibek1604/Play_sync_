import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../models/location_model.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/api_client.dart';

/// Abstract interface for location data source operations
abstract class LocationDataSource {
  /// Get current GPS position with high accuracy
  Future<Position> getCurrentPosition();

  /// Convert coordinates to human-readable address
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });

  /// Get full location with address
  Future<LocationModel> getCurrentLocationWithAddress();

  /// Send location to backend API
  Future<void> sendLocationToServer(LocationModel location);

  /// Request location permission
  Future<bool> requestLocationPermission();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Open app settings
  Future<bool> openAppSettings();
}

/// Implementation of LocationDataSource using geolocator, geocoding, and Dio
class LocationDataSourceImpl implements LocationDataSource {
  final ApiClient apiClient;

  LocationDataSourceImpl({required this.apiClient});

  @override
  Future<Position> getCurrentPosition() async {
    try {
      // Get position with high accuracy and timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return position;
    } catch (e) {
      throw Exception('Failed to get GPS position: ${e.toString()}');
    }
  }

  @override
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Reverse geocode coordinates to address
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Unknown Location';
      }

      final placemark = placemarks.first;

      // Build address string
      final addressParts = <String>[];

      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        addressParts.add(placemark.locality!);
      }
      if (placemark.administrativeArea != null &&
          placemark.administrativeArea!.isNotEmpty) {
        addressParts.add(placemark.administrativeArea!);
      }
      if (placemark.country != null && placemark.country!.isNotEmpty) {
        addressParts.add(placemark.country!);
      }

      return addressParts.isNotEmpty
          ? addressParts.join(', ')
          : 'Unknown Location';
    } catch (e) {
      throw Exception('Failed to get address: ${e.toString()}');
    }
  }

  @override
  Future<LocationModel> getCurrentLocationWithAddress() async {
    try {
      // Step 1: Get GPS position
      final position = await getCurrentPosition();

      // Step 2: Get address from coordinates
      final address = await getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Step 3: Extract location details
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      // Step 4: Create LocationModel
      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: placemark?.locality,
        state: placemark?.administrativeArea,
        country: placemark?.country,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get location with address: ${e.toString()}');
    }
  }

  @override
  Future<void> sendLocationToServer(LocationModel location) async {
    try {
      // Send location to backend using PATCH request
      await apiClient.dio.patch(
        ApiEndpoints.updateProfile,
        data: {
          'location': location.toJson(),
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Server error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to send location: ${e.toString()}');
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        return false;
      } else if (status.isPermanentlyDenied) {
        return false;
      }

      return false;
    } catch (e) {
      throw Exception('Failed to request permission: ${e.toString()}');
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw Exception('Failed to check location service: ${e.toString()}');
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Permission.location.request().then((status) async {
        if (status.isPermanentlyDenied) {
          return await openAppSettings();
        }
        return status.isGranted;
      });
    } catch (e) {
      throw Exception('Failed to open app settings: ${e.toString()}');
    }
  }
}

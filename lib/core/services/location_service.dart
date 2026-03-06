import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:play_sync_new/core/services/app_logger.dart';

/// Result from a location lookup.
class LocationResult {
  final double latitude;
  final double longitude;
  final String displayName;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

/// Reason why location detection failed.
enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationServiceException implements Exception {
  final LocationError error;
  final dynamic originalError;
  const LocationServiceException(this.error, {this.originalError});

  String get userMessage {
    return switch (error) {
      LocationError.serviceDisabled => 'Location services are disabled. Please enable GPS in settings.',
      LocationError.permissionDenied => 'Location permission was denied. Please allow location access.',
      LocationError.permissionDeniedForever =>
        'Location permission is permanently denied. Enable it in app settings.',
      LocationError.timeout => 'Location request timed out. Please try again.',
      LocationError.unknown => 'Could not determine your location.',
    };
  }
}

class LocationService {
  /// Requests permission if needed, then returns the current GPS position.
  /// Throws [LocationServiceException] on failure.
  static Future<Position> getCurrentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw const LocationServiceException(LocationError.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const LocationServiceException(LocationError.permissionDenied);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationServiceException(LocationError.permissionDeniedForever);
      }

      AppLogger.location('Requesting current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      AppLogger.location('Position acquired: ${position.latitude}, ${position.longitude}');
      return position;
    } on TimeoutException catch (e) {
      AppLogger.location('Location request timed out', isError: true, error: e);
      throw const LocationServiceException(LocationError.timeout);
    } catch (e) {
      if (e is LocationServiceException) rethrow;
      AppLogger.location('Error getting position', isError: true, error: e);
      throw LocationServiceException(LocationError.unknown, originalError: e);
    }
  }

  /// Gets the current position and reverse-geocodes it to a human-readable address.
  static Future<LocationResult> getCurrentLocationResult() async {
    final pos = await getCurrentPosition();
    final displayName = await _reverseGeocode(pos.latitude, pos.longitude);
    return LocationResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      displayName: displayName,
    );
  }

  /// Returns a display address string for the given coords, or a lat/lng fallback.
  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.subLocality?.isNotEmpty == true) p.subLocality!,
          if (p.locality?.isNotEmpty == true) p.locality!,
          if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea!,
          if (p.country?.isNotEmpty == true) p.country!,
        ];
        if (parts.isNotEmpty) return parts.take(2).join(', ');
      }
    } catch (_) {
      // fall through to coordinate fallback
    }
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  /// Simple permission check without requesting — useful for showing UI hints.
  static Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  /// Opens the device location settings page.
  static Future<void> openSettings() => Geolocator.openLocationSettings();
}

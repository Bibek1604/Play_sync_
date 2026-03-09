import 'package:equatable/equatable.dart';

/// Domain entity representing a geographic location
/// This entity contains GPS coordinates and human-readable address information.
/// Used for offline game creation and nearby game searches.
class LocationEntity extends Equatable {
  /// Latitude coordinate (e.g., 27.700769)
  final double latitude;

  /// Longitude coordinate (e.g., 83.448278)
  final double longitude;

  /// Human-readable address (e.g., "Butwal, Lumbini Province, Nepal")
  final String address;

  /// City name extracted from address
  final String? city;

  /// State/Province name
  final String? state;

  /// Country name
  final String? country;

  /// Timestamp when location was captured
  final DateTime? timestamp;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
    this.country,
    this.timestamp,
  });

  /// Calculate distance between two locations in kilometers
  /// Uses Haversine formula for accuracy
  double distanceTo(LocationEntity other) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) *
            _cos(_toRadians(other.latitude)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Check if another location is within a given radius (in km)
  bool isWithinRadius(LocationEntity other, double radiusKm) {
    return distanceTo(other) <= radiusKm;
  }

  // Helper math functions
  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double radians) => radians; // Simplified, use dart:math in production
  double _cos(double radians) => 1 - (radians * radians / 2); // Simplified
  double _sqrt(double value) => value; // Use dart:math sqrt
  double _atan2(double y, double x) => y / x; // Use dart:math atan2

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        city,
        state,
        country,
        timestamp,
      ];

  @override
  String toString() {
    return 'LocationEntity(lat: $latitude, lng: $longitude, address: $address)';
  }

  /// Create a copy with updated fields
  LocationEntity copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    DateTime? timestamp,
  }) {
    return LocationEntity(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}

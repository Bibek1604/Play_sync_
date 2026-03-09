import '../../domain/entities/location_entity.dart';

/// Data model for location with JSON serialization
/// This model extends LocationEntity and adds:
/// - JSON serialization/deserialization
/// - API response mapping
/// - Data validation
class LocationModel extends LocationEntity {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    required super.address,
    super.city,
    super.state,
    super.country,
    super.timestamp,
  });

  /// Create LocationModel from JSON
/// Used for parsing API responses
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// Convert LocationModel to JSON
/// Used for API requests
  @override
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

  /// Create LocationModel from domain entity
  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      timestamp: entity.timestamp,
    );
  }

  /// Convert to domain entity
  LocationEntity toEntity() {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      state: state,
      country: country,
      timestamp: timestamp,
    );
  }

  /// Create a copy with updated fields
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

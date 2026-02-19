import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Location State
class LocationState {
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Location Notifier
/// Uses mock coordinates for nearby games feature
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _initializeDefaultLocation();
  }

  void _initializeDefaultLocation() {
    // Initialize with default coordinates (example: San Francisco)
    state = state.copyWith(
      latitude: 37.7749,  // San Francisco latitude
      longitude: -122.4194, // San Francisco longitude
      isLoading: false,
    );
  }

  /// Get current location (returns mock coordinates)
  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true);

    try {
      // Using mock coordinates for now
      // In production, this could be replaced with actual location service
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate API call
      
      state = state.copyWith(
        latitude: 37.7749,  // Mock latitude
        longitude: -122.4194, // Mock longitude
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update location manually
  void setLocation(double latitude, double longitude) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      isLoading: false,
      error: null,
    );
  }

  /// Refresh location
  Future<void> refresh() async {
    await getCurrentLocation();
  }
}

/// Location Provider
final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

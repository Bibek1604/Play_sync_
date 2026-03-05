import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/send_location_to_server.dart';
import '../../../../../core/error/failures.dart';

/// Location state for UI
class LocationState {
  final LocationEntity? location;
  final bool isLoading;
  final String? errorMessage;
  final LocationStateType type;

  const LocationState({
    this.location,
    this.isLoading = false,
    this.errorMessage,
    this.type = LocationStateType.initial,
  });

  LocationState copyWith({
    LocationEntity? location,
    bool? isLoading,
    String? errorMessage,
    LocationStateType? type,
  }) {
    return LocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      type: type ?? this.type,
    );
  }

  factory LocationState.initial() {
    return const LocationState(
      type: LocationStateType.initial,
    );
  }

  factory LocationState.loading() {
    return const LocationState(
      isLoading: true,
      type: LocationStateType.loading,
    );
  }

  factory LocationState.success(LocationEntity location) {
    return LocationState(
      location: location,
      isLoading: false,
      type: LocationStateType.success,
    );
  }

  factory LocationState.error(String message) {
    return LocationState(
      isLoading: false,
      errorMessage: message,
      type: LocationStateType.error,
    );
  }

  factory LocationState.permissionDenied(String message) {
    return LocationState(
      isLoading: false,
      errorMessage: message,
      type: LocationStateType.permissionDenied,
    );
  }

  factory LocationState.gpsDisabled(String message) {
    return LocationState(
      isLoading: false,
      errorMessage: message,
      type: LocationStateType.gpsDisabled,
    );
  }
}

/// Location state types
enum LocationStateType {
  initial,
  loading,
  success,
  error,
  permissionDenied,
  gpsDisabled,
}

/// Location controller for managing location state
class LocationController extends StateNotifier<LocationState> {
  final GetCurrentLocation getCurrentLocation;
  final SendLocationToServer sendLocationToServer;

  LocationController({
    required this.getCurrentLocation,
    required this.sendLocationToServer,
  }) : super(LocationState.initial());

  /// Get current GPS location and update state
  Future<void> fetchCurrentLocation() async {
    // Set loading state
    state = LocationState.loading();

    // Execute use case
    final result = await getCurrentLocation();

    // Handle result
    result.fold(
      (failure) => _handleFailure(failure),
      (location) {
        state = LocationState.success(location);
      },
    );
  }

  /// Send current location to server
  Future<void> sendCurrentLocationToServer() async {
    if (state.location == null) {
      state = LocationState.error('No location available to send');
      return;
    }

    // Set loading state
    state = state.copyWith(isLoading: true);

    // Send to server
    final result = await sendLocationToServer(state.location!);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
      },
    );
  }

  /// Refresh location (fetch again)
  Future<void> refreshLocation() async {
    await fetchCurrentLocation();
  }

  /// Handle different failure types
  void _handleFailure(Failure failure) {
    if (failure is PermissionFailure) {
      state = LocationState.permissionDenied(failure.message);
    } else if (failure is LocationServiceFailure) {
      state = LocationState.gpsDisabled(failure.message);
    } else {
      state = LocationState.error(failure.message);
    }
  }

  /// Reset state to initial
  void reset() {
    state = LocationState.initial();
  }

  /// Check if location is available
  bool hasLocation() {
    return state.location != null;
  }

  /// Get location or null
  LocationEntity? getLocation() {
    return state.location;
  }
}

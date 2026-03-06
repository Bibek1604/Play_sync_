import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/location_datasource.dart';
import '../data/repositories/location_repository_impl.dart';
import '../domain/entities/location_entity.dart';
import '../domain/repositories/location_repository.dart';
import '../domain/usecases/get_current_location.dart';
import '../domain/usecases/send_location_to_server.dart';
import '../presentation/controllers/location_controller.dart';
import '../../../../core/api/api_client.dart';

/// Provider for LocationDataSource
final locationDataSourceProvider = Provider<LocationDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationDataSourceImpl(apiClient: apiClient);
});

/// Provider for LocationRepository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final dataSource = ref.watch(locationDataSourceProvider);
  return LocationRepositoryImpl(dataSource: dataSource);
});

/// Provider for GetCurrentLocation use case
final getCurrentLocationUseCaseProvider = Provider<GetCurrentLocation>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return GetCurrentLocation(repository);
});

/// Provider for SendLocationToServer use case
final sendLocationToServerUseCaseProvider =
    Provider<SendLocationToServer>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return SendLocationToServer(repository);
});

/// Provider for LocationController (State Notifier)
final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  final getCurrentLocation = ref.watch(getCurrentLocationUseCaseProvider);
  final sendLocationToServer = ref.watch(sendLocationToServerUseCaseProvider);

  return LocationController(
    getCurrentLocation: getCurrentLocation,
    sendLocationToServer: sendLocationToServer,
  );
});

/// Convenience provider to access current location entity
final currentLocationProvider = Provider<LocationEntity?>((ref) {
  return ref.watch(locationControllerProvider).location;
});

/// Convenience provider to check if location is loading
final isLocationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(locationControllerProvider).isLoading;
});

/// Convenience provider to get location error message
final locationErrorProvider = Provider<String?>((ref) {
  return ref.watch(locationControllerProvider).errorMessage;
});

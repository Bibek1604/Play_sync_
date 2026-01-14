import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';

/// Provider for connectivity service
final connectivityServiceProvider = Provider((ref) => ConnectivityService());

/// Service to check backend availability
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio();

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Check if backend server is reachable
  /// Returns true if backend is available, false otherwise
  Future<bool> isBackendAvailable() async {
    try {
      // First check internet connectivity
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        return false;
      }

      // Try to reach backend with a short timeout
      final response = await _dio.get(
        '${ApiEndpoints.baseUrl}/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (status) => true, // Accept all status codes
        ),
      );

      // Consider 2xx and 3xx as available
      return response.statusCode != null && response.statusCode! < 400;
    } catch (e) {
      // If we can't reach health endpoint, try a simpler check
      try {
        await _dio.get(
          ApiEndpoints.baseUrl,
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            validateStatus: (status) => true,
          ),
        );
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  /// Stream to monitor backend availability
  Stream<bool> monitorBackendAvailability({
    Duration checkInterval = const Duration(seconds: 30),
  }) async* {
    while (true) {
      final isAvailable = await isBackendAvailable();
      yield isAvailable;
      await Future.delayed(checkInterval);
    }
  }
}

/// Provider to check if backend is available
final isBackendAvailableProvider = FutureProvider<bool>((ref) async {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.isBackendAvailable();
});

/// Provider to stream backend availability
final backendAvailabilityStreamProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.monitorBackendAvailability();
});

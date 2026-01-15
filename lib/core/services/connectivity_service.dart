import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';

/// Provider for connectivity service
final connectivityServiceProvider = Provider((ref) => ConnectivityService());

/// Service to check backend availability
class ConnectivityService {
  final Dio _dio = Dio();

  /// Check if backend server is reachable
  /// Returns true if backend is available, false otherwise
  Future<bool> isBackendAvailable() async {
    try {
      debugPrint('[CONNECTIVITY] Checking backend at: ${ApiEndpoints.baseUrl}');
      
      // Try to reach backend root endpoint
      final response = await _dio.get(
        ApiEndpoints.baseUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => true, // Accept all status codes
        ),
      );

      final isAvailable = response.statusCode != null && response.statusCode! < 500;
      debugPrint('[CONNECTIVITY] Backend response: ${response.statusCode}, available: $isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('[CONNECTIVITY] Backend check failed: $e');
      return false;
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

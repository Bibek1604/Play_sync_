import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/core/services/connectivity_service.dart';
import 'package:play_sync_new/features/auth/data/datasources/auth_datasource.dart';
import 'package:play_sync_new/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:play_sync_new/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/constants/hive_table_constant.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Provider for Hive auth box
final hiveAuthBoxProvider = FutureProvider<Box<dynamic>>((ref) async {
  return Hive.openBox(HiveTableConstant.authBox);
});

/// Provider for local datasource
final authLocalDataSourceProvider = FutureProvider<AuthLocalDataSource>((ref) async {
  final authBox = await ref.watch(hiveAuthBoxProvider.future);
  return AuthLocalDataSource(authBox: authBox);
});

/// Provider for remote datasource
final authRemoteDatasourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRemoteDataSource(apiClient: apiClient, secureStorage: secureStorage);
});

/// Provider to determine which datasource to use
/// Intelligently switches between remote and local based on backend availability
final authDataSourceProvider = FutureProvider<IAuthDataSource>((ref) async {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final isBackendAvailable = await connectivityService.isBackendAvailable();

  if (isBackendAvailable) {
    // Backend is available, use remote datasource
    return ref.watch(authRemoteDatasourceProvider);
  } else {
    // Backend is not available, use local datasource (Hive)
    return ref.watch(authLocalDataSourceProvider.future);
  }
});

/// Provider for auth datasource with fallback
/// This provider will automatically switch between remote and local datasources
final smartAuthDataSourceProvider = FutureProvider<IAuthDataSource>((ref) async {
  try {
    // Try to use remote datasource first
    final connectivityService = ref.watch(connectivityServiceProvider);
    final isBackendAvailable = await connectivityService.isBackendAvailable();

    if (isBackendAvailable) {
      print('[AUTH] Backend available - using remote datasource');
      return ref.watch(authRemoteDatasourceProvider);
    } else {
      print('[AUTH] Backend not available - using local datasource (Hive)');
      return ref.watch(authLocalDataSourceProvider.future);
    }
  } catch (e) {
    print('[AUTH] Error determining datasource, falling back to local: $e');
    // Fallback to local datasource if anything goes wrong
    return ref.watch(authLocalDataSourceProvider.future);
  }
});

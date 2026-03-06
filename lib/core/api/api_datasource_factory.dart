import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/features/auth/data/datasources/auth_datasource.dart';
import 'package:play_sync_new/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:play_sync_new/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/constants/hive_table_constant.dart';



/// Provider for Hive auth box
final hiveAuthBoxProvider = FutureProvider<Box<dynamic>>((ref) async {
  return Hive.openBox(HiveTableConstant.authBox);
});

/// Provider for local datasource (used for reading cached data only — NOT for login/register)
final authLocalDataSourceProvider = FutureProvider<AuthLocalDataSource>((ref) async {
  final authBox = await ref.watch(hiveAuthBoxProvider.future);
  return AuthLocalDataSource(authBox: authBox);
});

/// Provider for remote datasource
final authRemoteDatasourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient: apiClient);
});

/// Auth datasource provider — ALWAYS uses the remote datasource.
/// Login and register require a live backend connection. If the server
/// is unreachable the remote datasource will throw a connection error,
/// which surfaces as a clear "No internet connection" / timeout message
/// to the user. There is no silent offline fallback for authentication.
final authDataSourceProvider = Provider<IAuthDataSource>((ref) {
  return ref.watch(authRemoteDatasourceProvider);
});

/// Smart auth datasource — same as authDataSourceProvider (always remote).
/// Kept for backwards compatibility with code that reads this provider.
final smartAuthDataSourceProvider = FutureProvider<IAuthDataSource>((ref) async {
  debugPrint('[AUTH] Using remote datasource (always required for login/register)');
  return ref.watch(authRemoteDatasourceProvider);
});

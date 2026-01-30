import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for secure storage
/// Configured to work on both mobile and web platforms
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  // Web options for browser compatibility
  const webOptions = WebOptions(
    dbName: 'PlaySyncSecureStorage',
    publicKey: 'PlaySyncApp',
  );
  
  // Android options for enhanced security
  const androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  
  return const FlutterSecureStorage(
    webOptions: webOptions,
    aOptions: androidOptions,
  );
});

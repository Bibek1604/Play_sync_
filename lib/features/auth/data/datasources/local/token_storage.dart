import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralised, type-safe wrapper around [FlutterSecureStorage] for auth tokens.
class TokenStorage {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userIdKey = 'auth_user_id';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Write ────────────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Clear ────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userIdKey),
    ]);
  }
}

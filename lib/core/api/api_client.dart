import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/api/secure_storage_provider.dart';
import 'package:play_sync_new/core/services/app_logger.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final client = ApiClient(secureStorage);
  ref.onDispose(client.dispose);
  return client;
});

/// Fires a single `void` event whenever the backend returns 401 and the
/// refresh-token exchange also fails (i.e. the session is truly dead).
final unauthorizedStreamProvider = StreamProvider<void>((ref) {
  return ref.watch(apiClientProvider).onUnauthorized;
});

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  bool _isRefreshing = false;

  /// Broadcasts a `void` event when a 401 cannot be recovered via refresh.
  final StreamController<void> _unauthorizedCtrl =
      StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedCtrl.stream;

  void dispose() => _unauthorizedCtrl.close();

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(this));

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => AppLogger.api(obj.toString()),
        ),
      );
    }
  }

  Dio get dio => _dio;
  FlutterSecureStorage get storage => _secureStorage;

  // ── Token helpers ──────────────────────────────────────────────────────

  Future<String?> get accessToken => _secureStorage.read(key: 'access_token');
  Future<String?> get refreshToken => _secureStorage.read(key: 'refresh_token');

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _secureStorage.write(key: 'access_token', value: access);
    await _secureStorage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_id');
  }

  /// Attempt to refresh the access token using the stored refresh token.
  /// Returns true on success.
  Future<bool> refreshAccessToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final storedRefresh = await _secureStorage.read(key: 'refresh_token');
      if (storedRefresh == null) {
        AppLogger.api('Refresh token not found', isError: true);
        return false;
      }

      // Use a fresh Dio to avoid interceptor recursion
      final freshDio = Dio(BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        contentType: Headers.jsonContentType,
      ));

      AppLogger.api('Attempting to refresh token...');
      final resp = await freshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': storedRefresh},
      );

      final data = resp.data as Map<String, dynamic>;
      final newAccess = data['accessToken'] as String? ??
          (data['data'] as Map<String, dynamic>?)?['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String? ??
          (data['data'] as Map<String, dynamic>?)?['refreshToken'] as String? ??
          storedRefresh;

      if (newAccess != null) {
        await saveTokens(access: newAccess, refresh: newRefresh);
        AppLogger.api('Token refreshed successfully');
        return true;
      }
      AppLogger.api('Refresh response did not contain new access token', isError: true);
      return false;
    } catch (e) {
      AppLogger.api('Token refresh failed', isError: true, error: e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ── HTTP verbs ─────────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.post(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.put(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.delete(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
}

/// Auth Interceptor — attaches token & auto-refreshes on 401.
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  /// Paths that must NOT carry a Bearer token.
  static const _publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh-token',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = _publicPaths.any((p) => options.path.contains(p));
    if (!isPublic) {
      final token = await _client.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final success = await _client.refreshAccessToken();
      if (success) {
        // Retry original request with the new token
        final opts = err.requestOptions;
        final newToken = await _client.accessToken;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final resp = await _client.dio.fetch(opts);
          return handler.resolve(resp);
        } on DioException catch (e) {
          return handler.next(e);
        }
      } else {
        // Refresh failed — session is dead.  Clear tokens and notify listeners.
        await _client.clearTokens();
        _client._unauthorizedCtrl.add(null);
      }
    }
    handler.next(err);
  }
}

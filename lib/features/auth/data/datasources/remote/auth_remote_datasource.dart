import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/auth/data/datasources/auth_datasource.dart';
import 'package:play_sync_new/features/auth/data/models/auth_request_model.dart';
import 'package:play_sync_new/features/auth/data/models/auth_response_model.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRemoteDataSource(apiClient: apiClient);
});

/// Remote data source for authentication - Handles API calls
class AuthRemoteDataSource implements IAuthDataSource {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  /// ========== REGISTER STUDENT ==========
  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    try {
      final requestModel = AuthRequestModel(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      debugPrint('[AUTH API] Registering user: ${requestModel.toRegisterJson()}');
      debugPrint('[AUTH API] Endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.registerUser}');

      final response = await _apiClient.post(
        ApiEndpoints.registerUser,
        data: requestModel.toRegisterJson(),
      );

      debugPrint('[AUTH API] Response: ${response.data}');
      final authResponse = AuthResponseModel.fromJson(response.data);

      // Save token if returned
      if (authResponse.token != null) {
        await _saveTokens(authResponse.token!, authResponse.refreshToken);
      }

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== LOGIN ==========
  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final requestModel = AuthRequestModel(
        email: email,
        password: password,
      );

      debugPrint('[AUTH API] Logging in: ${requestModel.toLoginJson()}');
      debugPrint('[AUTH API] Endpoint: ${ApiEndpoints.baseUrl}${ApiEndpoints.login}');

      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: requestModel.toLoginJson(),
      );

      debugPrint('[AUTH API] Response: ${response.data}');
      final authResponse = AuthResponseModel.fromJson(response.data);

      // Save tokens
      if (authResponse.token != null) {
        await _saveTokens(authResponse.token!, authResponse.refreshToken);
      }

      // Save user data
      await _saveUserData(authResponse);

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== LOGOUT ==========
  @override
  Future<bool> logout() async {
    try {
      // Clear all stored data
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.delete(key: 'user_role');
      await _secureStorage.delete(key: 'user_fullName');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ========== HELPER METHODS ==========

  /// Save tokens to secure storage
  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  /// Save user data to secure storage
  Future<void> _saveUserData(AuthResponseModel response) async {
    if (response.userId != null) {
      await _secureStorage.write(key: 'user_id', value: response.userId);
    }
    await _secureStorage.write(key: 'user_email', value: response.email);
    await _secureStorage.write(key: 'user_role', value: response.role);
    if (response.fullName != null) {
      await _secureStorage.write(key: 'user_fullName', value: response.fullName);
    }
  }

  /// Handle Dio errors and return meaningful exception
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        debugPrint('[AUTH API ERROR] Status: $statusCode, Response: $responseData');
        
        final message = (responseData is Map)
            ? (responseData['message'] ?? responseData['error'] ?? 'Unknown error')
            : responseData?.toString() ?? 'Unknown error';

        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Invalid credentials');
          case 403:
            return Exception('Access denied');
          case 404:
            return Exception('Endpoint not found');
          case 409:
            return Exception('User already exists');
          case 422:
            return Exception('Validation error: $message');
          case 500:
            return Exception('Server error: $message');
          default:
            return Exception('Error: $message');
        }

      case DioExceptionType.connectionError:
        return Exception('No internet connection');

      case DioExceptionType.cancel:
        return Exception('Request cancelled');

      default:
        return Exception('Something went wrong');
    }
  }
}

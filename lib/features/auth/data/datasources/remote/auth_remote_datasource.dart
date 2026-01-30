import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // Note: Repository handles saving tokens


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

      // Note: Repository handles saving tokens and user data

      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// ========== LOGOUT ==========
  @override
  Future<bool> logout() async {
    try {
      debugPrint('[AUTH API] Logging out');
      await _apiClient.post(ApiEndpoints.logout);
      return true;
    } catch (e) {
      // Even if API fails, we return true to allow local logout
      return true;
    }
  }

  /// ========== HELPER METHODS ==========

  /// Save tokens to secure storage


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

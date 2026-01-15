import 'package:play_sync_new/features/auth/data/models/auth_response_model.dart';

/// Abstract interface for authentication data sources
abstract interface class IAuthDataSource {
  /// Register user
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Login
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  /// Logout
  Future<bool> logout();
}

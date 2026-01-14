import 'package:play_sync_new/features/auth/data/models/auth_response_model.dart';

/// Abstract interface for authentication data sources
abstract interface class IAuthDataSource {
  /// Register student
  Future<AuthResponseModel> register({
    required String email,
    required String password,
  });

  /// Register admin
  Future<AuthResponseModel> registerAdmin({
    required String email,
    required String password,
  });

  /// Register tutor
  Future<AuthResponseModel> registerTutor({
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

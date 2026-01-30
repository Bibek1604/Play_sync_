import 'package:hive_flutter/hive_flutter.dart';
import 'package:play_sync_new/features/auth/data/datasources/auth_datasource.dart';
import 'package:play_sync_new/features/auth/data/models/auth_response_model.dart';
import 'package:uuid/uuid.dart';


class AuthLocalDataSource implements IAuthDataSource {
  final Box<dynamic> _authBox;

  AuthLocalDataSource({required Box<dynamic> authBox}) : _authBox = authBox;

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      
      if (_authBox.containsKey('user_$normalizedEmail')) {
        throw Exception('User already registered');
      }

      final userId = const Uuid().v4();
      final userData = {
        'userId': userId,
        'fullName': fullName,
        'email': normalizedEmail,
        'password': password,
        'role': 'user',
        'token': 'local_token_$userId',
        'refreshToken': 'local_refresh_$userId',
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save locally
      await _authBox.put('user_$normalizedEmail', userData);
      
      return AuthResponseModel.fromJson(userData);
    } catch (e) {
      throw Exception('Local registration failed: $e');
    }
  }

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      
      // Try to find user in any role
      final user = _authBox.get('user_$normalizedEmail') ??
          _authBox.get('admin_$normalizedEmail');
      
      if (user == null) {
        throw Exception('User not found');
      }

      final userMap = user as Map<dynamic, dynamic>;
      
      // Verify password
      if (userMap['password'] != password) {
        throw Exception('Invalid password');
      }

      // Convert to proper map
      final userData = {
        'userId': userMap['userId'],
        'fullName': userMap['fullName'],
        'email': userMap['email'],
        'password': userMap['password'],
        'role': userMap['role'] ?? 'user',
        'token': 'local_token_${userMap['userId']}',
        'refreshToken': 'local_refresh_${userMap['userId']}',
        'createdAt': userMap['createdAt'],
      };
      
      return AuthResponseModel.fromJson(userData);
    } catch (e) {
      throw Exception('Local login failed: $e');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await _authBox.clear();
      return true;
    } catch (e) {
      throw Exception('Local logout failed: $e');
    }
  }

  /// Get all cached users
  List<Map<String, dynamic>> getAllCachedUsers() {
    try {
      final users = <Map<String, dynamic>>[];
      for (final key in _authBox.keys) {
        final user = _authBox.get(key);
        if (user is Map) {
          users.add(Map<String, dynamic>.from(user));
        }
      }
      return users;
    } catch (e) {
      return [];
    }
  }
}

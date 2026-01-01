import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user_model.dart';
import '../../../../../core/database/hive_service.dart';

abstract class AuthLocalDatasource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearUser();
  
  // Registration methods
  Future<void> registerUser(String email, String password, String? name);
  Future<UserModel?> validateLogin(String email, String password);
  Future<bool> isEmailRegistered(String email);
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  static const String _registeredUsersBox = 'registered_users';
  
  Future<Box<Map>> _getRegisteredUsersBox() async {
    if (!Hive.isBoxOpen(_registeredUsersBox)) {
      return await Hive.openBox<Map>(_registeredUsersBox);
    }
    return Hive.box<Map>(_registeredUsersBox);
  }
  
  @override
  Future<UserModel?> getCachedUser() async {
    final box = await HiveService.openUserBox();
    final user = box.get('user');
    if (user != null && user is UserModel) {
      return user;
    }
    return null;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final box = await HiveService.openUserBox();
    await box.put('user', user);
  }

  @override
  Future<void> clearUser() async {
    final box = await HiveService.openUserBox();
    await box.delete('user');
  }
  
  @override
  Future<void> registerUser(String email, String password, String? name) async {
    final box = await _getRegisteredUsersBox();
    final normalizedEmail = email.toLowerCase().trim();
    
    // Store user with hashed password (in production, use proper hashing)
    await box.put(normalizedEmail, {
      'id': normalizedEmail.hashCode.toString(),
      'email': normalizedEmail,
      'password': password, // In production, hash this!
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
  
  @override
  Future<UserModel?> validateLogin(String email, String password) async {
    final box = await _getRegisteredUsersBox();
    final normalizedEmail = email.toLowerCase().trim();
    
    final userData = box.get(normalizedEmail);
    if (userData == null) {
      return null; // Email not registered
    }
    
    // Check password
    if (userData['password'] != password) {
      return null; // Wrong password
    }
    
    // Return user model with a new token
    return UserModel(
      id: userData['id'] as String,
      email: userData['email'] as String,
      name: userData['name'] as String?,
      token: 'token_${normalizedEmail}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
  
  @override
  Future<bool> isEmailRegistered(String email) async {
    final box = await _getRegisteredUsersBox();
    final normalizedEmail = email.toLowerCase().trim();
    return box.containsKey(normalizedEmail);
  }
}

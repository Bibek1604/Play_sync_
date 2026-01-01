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
    final box = await HiveService.openRegisteredUsersBox();
    final normalizedEmail = email.toLowerCase().trim();
    
    // Store user with password
    await box.put(normalizedEmail, {
      'id': normalizedEmail.hashCode.toString(),
      'email': normalizedEmail,
      'password': password,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    // Force flush to disk
    await box.flush();
  }
  
  @override
  Future<UserModel?> validateLogin(String email, String password) async {
    final box = await HiveService.openRegisteredUsersBox();
    final normalizedEmail = email.toLowerCase().trim();
    
    final userData = box.get(normalizedEmail);
    if (userData == null) {
      return null; // Email not registered
    }
    
    // Cast to Map<dynamic, dynamic>
    final Map<dynamic, dynamic> userMap = userData as Map<dynamic, dynamic>;
    
    // Check password
    if (userMap['password'] != password) {
      return null; // Wrong password
    }
    
    // Return user model with a new token
    return UserModel(
      id: userMap['id'] as String,
      email: userMap['email'] as String,
      name: userMap['name'] as String?,
      token: 'token_${normalizedEmail}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
  
  @override
  Future<bool> isEmailRegistered(String email) async {
    final box = await HiveService.openRegisteredUsersBox();
    final normalizedEmail = email.toLowerCase().trim();
    return box.containsKey(normalizedEmail);
  }
}

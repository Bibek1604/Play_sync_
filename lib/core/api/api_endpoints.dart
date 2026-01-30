import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// API Endpoints for the application
class ApiEndpoints {
  ApiEndpoints._();

  // ========== BASE URL & TIMEOUTS ==========
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    
    // For Android Emulator, use 10.0.2.2 to access host's localhost
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
      }
    } catch (_) {
      // Platform check may fail on some web environments if not handled by kIsWeb
    }
    
    return 'http://localhost:5000/api/v1';
  }

  // ========== IMAGE BASE URL ==========
  static String get imageBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000';
      }
    } catch (_) {
      // Platform check may fail
    }
    
    return 'http://localhost:5000';
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ========== AUTH ENDPOINTS ==========
  static const String registerUser = '/auth/register/user';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String getCurrentUser = '/auth/me';

  // ========== PROFILE ENDPOINTS ==========
  static const String getProfile = '/profile';
  static const String updateProfile = '/profile';
  static const String uploadProfilePicture = '/profile/avatar';
  static const String uploadCoverPicture = '/profile/cover';
  static const String uploadGalleryPictures = '/profile/pictures';
  static const String deleteProfilePicture = '/profile/avatar';

  // ========== USER ENDPOINTS ==========
  // static const String getUsers = '/users';
  // static const String getUserById = '/users/:id';
  // static const String updateUser = '/users/:id';
  // static const String deleteUser = '/users/:id';

  // ========== PRODUCT ENDPOINTS ==========
  // static const String getProducts = '/products';
  // static const String getProductById = '/products/:id';
  // static const String createProduct = '/products';
  // static const String updateProduct = '/products/:id';
  // static const String deleteProduct = '/products/:id';

  // ========== ADMIN CODE ==========
  static const String adminCode = 'your-super-secret-key-2025';
}

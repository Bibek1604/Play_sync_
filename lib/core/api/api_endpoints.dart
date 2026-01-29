/// API Endpoints for the application
class ApiEndpoints {
  ApiEndpoints._();

  // ========== BASE URL & TIMEOUTS ==========
  static const String baseUrl = 'http://localhost:5000/api/v1';

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

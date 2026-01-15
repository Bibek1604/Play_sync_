/// API Endpoints for the application
class ApiEndpoints {
  ApiEndpoints._();

  // ========== BASE URL & TIMEOUTS ==========
  // Base URL - Change based on environment
  static const String baseUrl = 'http://localhost:5000';
  
  // For Android Emulator: 'http://10.0.2.2:5000'
  // For iOS Simulator: 'http://localhost:5000'
  // For Physical Device: 'http://192.168.x.x:5000'

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ========== AUTH ENDPOINTS ==========
  static const String registerUser = '/auth/register/user';
  static const String registerAdmin = '/auth/register/admin';
  static const String registerTutor = '/auth/register/tutor';
  static const String login = '/auth/login';  // Fixed: was /api/auth/login
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String getCurrentUser = '/auth/me';

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

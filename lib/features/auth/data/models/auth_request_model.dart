/// Request model for authentication API calls
class AuthRequestModel {
  final String? fullName;
  final String email;
  final String password;
  final String? adminCode;

  AuthRequestModel({
    this.fullName,
    required this.email,
    required this.password,
    this.adminCode,
  });

  /// Convert to JSON for login requests (email + password only)
  Map<String, dynamic> toLoginJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Convert to JSON for registration requests (includes fullName)
  Map<String, dynamic> toRegisterJson() {
    return {
      'fullName': fullName ?? '',
      'email': email,
      'password': password,
    };
  }

  /// Convert to JSON for admin registration (includes adminCode)
  Map<String, dynamic> toAdminRegisterJson() {
    return {
      'fullName': fullName ?? '',
      'email': email,
      'password': password,
      'adminCode': adminCode ?? '',
    };
  }
}

/// Request model for authentication API calls
class AuthRequestModel {
  final String? fullName;
  final String email;
  final String password;
  final String? confirmPassword;

  AuthRequestModel({
    this.fullName,
    required this.email,
    required this.password,
    this.confirmPassword,
  });

  /// Convert to JSON for login requests
  Map<String, dynamic> toLoginJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  /// Convert to JSON for registration requests
  Map<String, dynamic> toRegisterJson() {
    return {
      'fullName': fullName ?? '',
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword ?? password,
    };
  }
}

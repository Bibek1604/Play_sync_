/// Request model for authentication API calls
class AuthRequestModel {
  final String email;
  final String password;

  AuthRequestModel({
    required this.email,
    required this.password,
  });

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

import 'package:flutter_test/flutter_test.dart';

// Assuming this is your model (paste your actual class here if different)
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

  Map<String, dynamic> toLoginJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  Map<String, dynamic> toRegisterJson() {
    return {
      'fullName': fullName ?? '',
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword ?? password,
    };
  }
}

void main() {
  group('AuthRequestModel', () {
    test('toLoginJson should return only email and password', () {
      final model = AuthRequestModel(
        fullName: 'Bibek Shrestha',
        email: 'bibek@example.com',
        password: 'Pass123!',
        confirmPassword: 'Pass123!',
      );

      final json = model.toLoginJson();

      expect(json, {
        'email': 'bibek@example.com',
        'password': 'Pass123!',
      });
      expect(json.length, 2); // no extra fields
      expect(json.containsKey('fullName'), false);
      expect(json.containsKey('confirmPassword'), false);
    });

    test('toRegisterJson should include fullName when provided', () {
      final model = AuthRequestModel(
        fullName: 'Bibek Shrestha',
        email: 'bibek@example.com',
        password: 'secret123',
        confirmPassword: 'secret123',
      );

      final json = model.toRegisterJson();

      expect(json, {
        'fullName': 'Bibek Shrestha',
        'email': 'bibek@example.com',
        'password': 'secret123',
        'confirmPassword': 'secret123',
      });
    });

    test('toRegisterJson should use empty string when fullName is null', () {
      final model = AuthRequestModel(
        fullName: null,
        email: 'test@domain.com',
        password: 'abc123',
      );

      final json = model.toRegisterJson();

      expect(json['fullName'], '');
      expect(json['confirmPassword'], 'abc123'); // fallback to password
    });

    test('toRegisterJson should fallback to password when confirmPassword is null', () {
      final model = AuthRequestModel(
        fullName: 'John Doe',
        email: 'john@example.com',
        password: 'myPass456',
        confirmPassword: null,
      );

      final json = model.toRegisterJson();

      expect(json['confirmPassword'], 'myPass456');
    });

    test('model allows null fullName and confirmPassword (constructor)', () {
      final model = AuthRequestModel(
        email: 'minimal@example.com',
        password: 'pass',
      );

      expect(model.fullName, null);
      expect(model.confirmPassword, null);
      expect(model.email, 'minimal@example.com');
      expect(model.password, 'pass');
    });

    test('toLoginJson works correctly even when optional fields are set', () {
      final model = AuthRequestModel(
        fullName: 'Extra Name',
        email: 'login@only.com',
        password: 'loginPass',
        confirmPassword: 'something else',
      );

      final json = model.toLoginJson();

      expect(json, {
        'email': 'login@only.com',
        'password': 'loginPass',
      });
    });
  });
}
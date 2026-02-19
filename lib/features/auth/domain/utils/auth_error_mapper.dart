import 'package:play_sync_new/core/error/failures.dart';

/// Maps backend Failure types to human-readable, user-friendly messages.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String toMessage(Failure failure) {
    final msg = failure.message.toLowerCase();

    if (msg.contains('invalid credentials') || msg.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('user not found') || msg.contains('no user')) {
      return 'No account found with this email. Please sign up.';
    }
    if (msg.contains('email already') || msg.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your internet connection.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('token') || msg.contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.contains('too many')) {
      return 'Too many attempts. Please wait and try again.';
    }

    // Fallback to raw message, capitalised
    final raw = failure.message;
    return raw.isNotEmpty
        ? '${raw[0].toUpperCase()}${raw.substring(1)}'
        : 'Something went wrong. Please try again.';
  }
}

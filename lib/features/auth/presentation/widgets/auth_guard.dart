import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';

/// A widget that protects routes requiring authentication.
/// If user is not logged in, redirects to login page.
class AuthGuard extends ConsumerWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Show loading while checking auth state
    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ),
      );
    }

    // If not logged in, redirect to login
    if (authState.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text(
                'Please login to continue',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ),
      );
    }

    // User is authenticated, show the protected content
    return child;
  }
}

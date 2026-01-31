import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ────────────────────────────────────────────────
//  Fake / Mock version for testing
// ────────────────────────────────────────────────
class FakeAuthState {
  final bool isLoading;
  final Object? user; // usually null or some User model

  FakeAuthState({required this.isLoading, this.user});
}

final authNotifierProvider = StateProvider<FakeAuthState>((ref) {
  throw UnimplementedError('Should be overridden in tests');
});

// For real code you'd have something like:
// class AuthState { bool isLoading; User? user; ... }
// but for tests we simulate it this way

// Your real widget (just copied here for completeness)
class AuthGuard extends ConsumerWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

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

    return child;
  }
}

void main() {
  group('AuthGuard', () {
    testWidgets('shows loading indicator when isLoading = true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => FakeAuthState(
                  isLoading: true,
                  user: null,
                )),
          ],
          child: const MaterialApp(
            home: AuthGuard(
              child: Scaffold(body: Text('Protected Content')),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Checking authentication...'), findsOneWidget);
      expect(find.text('Protected Content'), findsNothing);
    });

    testWidgets('shows "Please login" screen and triggers navigation when not logged in', (tester) async {
      final navigatorObserver = _FakeNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => FakeAuthState(
                  isLoading: false,
                  user: null,
                )),
          ],
          child: MaterialApp(
            navigatorObservers: [navigatorObserver],
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthGuard(
                    child: Scaffold(body: Text('Secret Page')),
                  ),
              '/login': (context) => const Scaffold(body: Text('Login Screen')),
            },
          ),
        ),
      );

      // Give time for addPostFrameCallback to run
      await tester.pumpAndSettle();

      expect(find.text('Please login to continue'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Secret Page'), findsNothing);

      // Verify navigation was attempted
      expect(navigatorObserver.pushedRoutes.last, '/login');
    });

    testWidgets('shows child widget when user is logged in', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => FakeAuthState(
                  isLoading: false,
                  user: 'some-user-object', // non-null = logged in
                )),
          ],
          child: const MaterialApp(
            home: AuthGuard(
              child: Scaffold(
                body: Center(child: Text('You shall pass!')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You shall pass!'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Please login to continue'), findsNothing);
    });

    testWidgets('does not show loading forever if state changes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) => FakeAuthState(
                isLoading: true,
                user: null,
              )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AuthGuard(
              child: Text('Protected'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate auth finished
      container.read(authNotifierProvider.notifier).state = FakeAuthState(
        isLoading: false,
        user: Object(),
      );

      await tester.pumpAndSettle();

      expect(find.text('Protected'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}

// Helper to detect navigation calls
class _FakeNavigatorObserver extends NavigatorObserver {
  final List<String> pushedRoutes = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      pushedRoutes.add(name);
    }
  }
}
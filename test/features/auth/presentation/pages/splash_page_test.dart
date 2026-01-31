import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef AuthState = ({bool isLoading, FakeUser? user});

class FakeUser { final String? token; FakeUser({this.token}); }

final authProvider = StateProvider<AuthState>((_) => (isLoading: false, user: null));

class Routes {
  static const dashboard = '/dashboard';
  static const login = '/login';
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;
    _navigated = true;

    final state = ref.read(authProvider);
    if (state.user != null && (state.user!.token?.isNotEmpty ?? false)) {
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    } else {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Splash')));
}

void main() {
  group('Splash', () {
    testWidgets('goes to dashboard when logged in', (t) async {
      final obs = _Obs();

      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => (isLoading: false, user: FakeUser(token: 'abc123'))),
          ],
          child: MaterialApp(
            navigatorObservers: [obs],
            home: const SplashPage(),
            routes: {
              Routes.dashboard: (_) => const Text('Dashboard'),
              Routes.login: (_) => const Text('Login'),
            },
          ),
        ),
      );

      await t.pump(const Duration(milliseconds: 1600));
      await t.pumpAndSettle();

      expect(obs.lastReplaced, Routes.dashboard);
    });

    testWidgets('goes to login when not logged in', (t) async {
      final obs = _Obs();

      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => (isLoading: false, user: null)),
          ],
          child: MaterialApp(
            navigatorObservers: [obs],
            home: const SplashPage(),
            routes: {
              Routes.dashboard: (_) => const Text('Dashboard'),
              Routes.login: (_) => const Text('Login'),
            },
          ),
        ),
      );

      await t.pump(const Duration(milliseconds: 1600));
      await t.pumpAndSettle();

      expect(obs.lastReplaced, Routes.login);
    });
  });
}

class _Obs extends NavigatorObserver {
  String? lastReplaced;
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    lastReplaced = newRoute?.settings.name;
  }
}
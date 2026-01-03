import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:play_sync_new/screens/dashboard_screen.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:play_sync_new/core/error/failure.dart';
import 'package:play_sync_new/features/auth/domain/entities/user.dart';
import 'package:play_sync_new/features/auth/domain/usecases/login.dart';
import 'package:play_sync_new/features/auth/domain/usecases/signup.dart';
import 'package:play_sync_new/features/auth/domain/usecases/get_cached_user.dart';
import 'package:play_sync_new/features/auth/domain/usecases/logout.dart';

void main() {
  testWidgets('Dashboard renders Quick Actions and 4 cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            final repo = _FakeAuthRepository();
            return _FakeAuthNotifier(
              login: Login(repo),
              signup: Signup(repo),
              getCachedUser: GetCachedUser(repo),
              logout: Logout(repo),
            );
          }),
        ],
        child: const MediaQuery(
          data: MediaQueryData(size: Size(800, 1280)),
          child: MaterialApp(
            home: Scaffold(body: DashboardScreen()),
          ),
        ),
      ),
    );

    expect(find.text('Quick Actions'), findsOneWidget);
    // Expect at least 4 action cards (Icons present)
    expect(find.byIcon(Icons.group_add), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.leaderboard), findsOneWidget);
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier({
    required Login login,
    required Signup signup,
    required GetCachedUser getCachedUser,
    required Logout logout,
  }) : super(
          login: login,
          signup: signup,
          getCachedUser: getCachedUser,
          logout: logout,
        );
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    return Right(User(id: '1', email: email, name: 'Test User', token: 'fake-token'));
  }

  @override
  Future<Either<Failure, User>> signup(String email, String password, {String? name}) async {
    return Right(User(id: '2', email: email, name: name ?? 'New User', token: 'fake-token'));
  }

  @override
  Future<Either<Failure, User?>> getCachedUser() async {
    // No cached user in tests
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/screens/dashboard_screen.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/auth/domain/usecases/login_usecase.dart';
import 'package:play_sync_new/features/auth/domain/usecases/register_usecase.dart';
import 'package:play_sync_new/features/auth/domain/usecases/register_admin_usecase.dart';
import 'package:play_sync_new/features/auth/domain/usecases/register_tutor_usecase.dart';

void main() {
  testWidgets('Dashboard renders Quick Actions and 4 cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth provider with unauthenticated state
          authNotifierProvider.overrideWith((ref) {
            return _TestAuthNotifier();
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

    // Wait for async operations
    await tester.pumpAndSettle();

    expect(find.text('Quick Actions'), findsOneWidget);
    // Expect at least 4 action cards (Icons present)
    expect(find.byIcon(Icons.group_add), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    expect(find.byIcon(Icons.leaderboard), findsOneWidget);
  });
}

/// Test auth notifier that provides unauthenticated state
class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier()
      : super(
          loginUsecase: _FakeLoginUsecase(),
          registerUsecase: _FakeRegisterUsecase(),
          registerAdminUsecase: _FakeRegisterAdminUsecase(),
          registerTutorUsecase: _FakeRegisterTutorUsecase(),
          ref: _FakeRef(),
        );
}

// Fake implementations for testing
class _FakeLoginUsecase extends Fake implements LoginUsecase {}
class _FakeRegisterUsecase extends Fake implements RegisterUsecase {}
class _FakeRegisterAdminUsecase extends Fake implements RegisterAdminUsecase {}
class _FakeRegisterTutorUsecase extends Fake implements RegisterTutorUsecase {}
class _FakeRef extends Fake implements Ref {}

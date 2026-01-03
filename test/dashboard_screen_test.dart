import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/screens/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard renders Quick Actions and 4 cards', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DashboardScreen()),
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

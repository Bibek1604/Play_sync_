import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/history/presentation/pages/game_history_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../app/routes/app_routes.dart';
import '../../core/api/api_client.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';

/// Provider that tracks the active bottom-nav tab index.
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Authenticated shell widget that hosts the bottom navigation bar.
/// Also acts as the single listener for session-expiry (401) events — if the
/// API cannot refresh the token it broadcasts [unauthorizedStreamProvider],
/// which we catch here to force-logout the user and redirect to login.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _tabs = [
    DashboardPage(),
    GameHistoryPage(),
    LeaderboardPage(),
    ProfilePage(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_rounded),
      selectedIcon: Icon(Icons.history),
      label: 'History',
    ),
    NavigationDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard_rounded),
      label: 'Rankings',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Session-expiry listener ────────────────────────────────────────────
    // Fires when the API returns 401 AND the refresh-token exchange fails.
    ref.listen<AsyncValue<void>>(unauthorizedStreamProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(authNotifierProvider.notifier).forceLogout();
          // Navigate to login, clearing the entire back-stack.
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        },
      );
    });

    final currentIndex = ref.watch(shellIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedIndex: currentIndex,
          onDestinationSelected: (i) =>
              ref.read(shellIndexProvider.notifier).state = i,
          destinations: _destinations,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
    );
  }
}

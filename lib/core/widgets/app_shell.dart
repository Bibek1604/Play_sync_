import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/tournament/presentation/pages/tournament_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../app/routes/app_routes.dart';
import '../../core/api/api_client.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

/// Provider that tracks the active bottom-nav tab index.
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Authenticated shell widget that hosts the bottom navigation bar.
/// Also acts as the single listener for session-expiry (401) events — if the
/// API cannot refresh the token it broadcasts [unauthorizedStreamProvider],
/// which we catch here to force-logout the user and redirect to login.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.leaderboard_outlined),
      selectedIcon: Icon(Icons.leaderboard_rounded),
      label: 'Leaderboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events_rounded),
      label: 'Tournaments',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    final tabs = [
      const DashboardPage(),
      const LeaderboardPage(),
      const TournamentListPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: tabs[currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D21) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: NavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            selectedIndex: currentIndex,
            onDestinationSelected: (i) =>
                ref.read(shellIndexProvider.notifier).state = i,
            destinations: _destinations.map((d) {
              return NavigationDestination(
                icon: d.icon,
                selectedIcon: Icon(
                  (d.selectedIcon as Icon).icon,
                  color: AppColors.primary,
                ),
                label: d.label,
              );
            }).toList(),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          ),
        ),
      ),
    );
  }
}

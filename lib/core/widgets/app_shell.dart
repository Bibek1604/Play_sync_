import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../app/routes/app_routes.dart';
import '../../core/api/api_client.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';

/// Provider that tracks the active bottom-nav tab index.
final shellIndexProvider = StateProvider<int>((ref) => 0);

// ── Nav item model ─────────────────────────────────────────────────────────────
class _NavDest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavDest({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _destinations = [
  _NavDest(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _NavDest(
    icon: Icons.leaderboard_outlined,
    activeIcon: Icons.leaderboard_rounded,
    label: 'Ranks',
  ),
  _NavDest(
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'Chats',
  ),
  _NavDest(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Session-expiry listener ────────────────────────────────────────────
    ref.listen<AsyncValue<void>>(unauthorizedStreamProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(authNotifierProvider.notifier).forceLogout();
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        },
      );
    });

    final currentIndex = ref.watch(shellIndexProvider);

    final tabs = [
      const DashboardPage(),
      const LeaderboardPage(),
      ChatPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: tabs[currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: currentIndex,
        isDark: isDark,
        onTap: (i) {
          HapticFeedback.selectionClick();
          ref.read(shellIndexProvider.notifier).state = i;
        },
      ),
    );
  }
}

// ─── Custom Bottom Bar ────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dashboard bluish tone: light mode uses #E0E7FF → white gradient
    // Bottom bar mirrors that palette
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                // Lighter Sky-blue tint matching sidebar/profile
                colors: [Color(0xFFF0F9FF), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : const Color(0xFF0284C7).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFBAE6FD).withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _destinations.length,
              (i) => _NavItem(
                dest: _destinations[i],
                isActive: i == currentIndex,
                isDark: isDark,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Individual Nav Item ──────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavDest dest;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.dest,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  // Active colour matches primary nav blue (#0284C7) from profile/sidebar
  static const _activeColor = Color(0xFF0284C7);
  static final _activeDark = const Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context) {
    final active = isDark ? _activeDark : _activeColor;
    final inactive = isDark
        ? Colors.white.withOpacity(0.3)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutBack, // Smoother, less "snappy" feeling
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          // Soft sky-blue active background
          color: isActive
              ? (isDark
                    ? const Color(0xFF0EA5E9).withOpacity(0.15)
                    : const Color(0xFFE0F2FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? dest.activeIcon : dest.icon,
              size: 24,
              color: isActive ? active : inactive,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                dest.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: active,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/leaderboard/presentation/pages/rankings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Shell index provider — tracks which bottom-nav tab is active
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// AppShell
///
/// Persistent scaffold wrapping all authenticated screens.
/// Owns the BottomNavigationBar and the side Drawer so they are
/// never rebuilt on tab-switch.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = [
    DashboardPage(),
    RankingsPage(),
    ChatPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _pages,
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: index,
        isDark: isDark,
        onTap: (i) => ref.read(shellIndexProvider.notifier).state = i,
      ),
    );
  }
}

/// Bottom Navigation Bar
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
    final bg = isDark ? AppColors.backgroundSecondaryDark : Colors.white;
    final selected = AppColors.emerald500;
    final unselected = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                selectedColor: selected,
                unselectedColor: unselected,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.leaderboard_rounded,
                label: 'Rankings',
                selected: currentIndex == 1,
                selectedColor: selected,
                unselectedColor: unselected,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                selected: currentIndex == 2,
                selectedColor: selected,
                unselectedColor: unselected,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                selected: currentIndex == 3,
                selectedColor: selected,
                unselectedColor: unselected,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: currentIndex == 4,
                selectedColor: selected,
                unselectedColor: unselected,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? selectedColor.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? selectedColor : unselectedColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? selectedColor : unselectedColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

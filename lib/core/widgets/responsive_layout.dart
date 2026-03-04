import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/game/presentation/pages/available_games_page.dart';
import '../../features/history/presentation/pages/game_history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../constants/app_colors.dart';
import 'app_drawer.dart';

class ResponsiveLayout extends StatefulWidget {
  final int initialIndex;
  const ResponsiveLayout({super.key, this.initialIndex = 0});

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = const [
      DashboardPage(),
      AvailableGamesPage(),
      GameHistoryPage(),
      ProfilePage(), // Could also be ScorecardPage, etc.
    ];
  }

  void _onNavigate(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.mediumImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;
    final isMiniMobile = MediaQuery.of(context).size.width < 360; // Helper for extra narrow
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop || isTablet) {
      // Desktop / Tablet Sidebar Layout
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Floating, Curved Sidebar
            Container(
              width: isDesktop ? 260 : 200, // Slightly thinner on tablet
              margin: const EdgeInsets.only(right: 4), // Breathing room
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    // App Logo or Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_esports, color: AppColors.primary, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'PlaySync',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    // Navigation Items
                    _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', idx: 0, current: _currentIndex, onTap: () => _onNavigate(0)),
                    _SidebarItem(icon: Icons.explore_rounded, label: 'Discover', idx: 1, current: _currentIndex, onTap: () => _onNavigate(1)),
                    _SidebarItem(icon: Icons.history_rounded, label: 'Records', idx: 2, current: _currentIndex, onTap: () => _onNavigate(2)),
                    _SidebarItem(icon: Icons.person_rounded, label: 'Profile', idx: 3, current: _currentIndex, onTap: () => _onNavigate(3)),
                    const Spacer(),
                    const Divider(height: 1, indent: 24, endIndent: 24),
                    const SizedBox(height: 24),
                    // Optional: Logout or Settings at bottom
                    _SidebarItem(icon: Icons.settings_rounded, label: 'Settings', idx: 99, current: _currentIndex, onTap: () {}),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Bottom Navigation Layout
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // Allow content to scroll behind the floating bar
      drawer: const AppDrawer(),
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
            borderRadius: BorderRadius.circular(35), // Pill shape
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 4;
              // Animated pill position and size
              final indicatorWidth = 50.0;
              final indicatorOffset = (tabWidth * _currentIndex) + (tabWidth / 2) - (indicatorWidth / 2);

              return Stack(
                children: [
                  // Animated active indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    left: indicatorOffset,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: indicatorWidth,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Icons overlay
                  Row(
                    children: [
                      _BottomNavItem(icon: Icons.dashboard_rounded, idx: 0, current: _currentIndex, onTap: () => _onNavigate(0), mini: isMiniMobile),
                      _BottomNavItem(icon: Icons.explore_rounded, idx: 1, current: _currentIndex, onTap: () => _onNavigate(1), mini: isMiniMobile),
                      _BottomNavItem(icon: Icons.history_rounded, idx: 2, current: _currentIndex, onTap: () => _onNavigate(2), mini: isMiniMobile),
                      _BottomNavItem(icon: Icons.person_rounded, idx: 3, current: _currentIndex, onTap: () => _onNavigate(3), mini: isMiniMobile),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int idx;
  final int current;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.idx,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = idx == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Left active indicator line
            if (isActive)
              Positioned(
                left: -24, // Pull to the edge
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    icon,
                    color: isActive 
                        ? AppColors.primary 
                        : (isDark ? Colors.white54 : AppColors.textTertiary),
                    size: isActive ? 26 : 24, // Micro animation scale up
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive 
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final int idx;
  final int current;
  final VoidCallback onTap;
  final bool mini;

  const _BottomNavItem({
    required this.icon,
    required this.idx,
    required this.current,
    required this.onTap,
    required this.mini,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = idx == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()..scale(isActive ? 1.15 : 1.0),
            child: Icon(
              icon,
              size: mini ? 22 : 26,
              color: isActive 
                  ? Colors.white 
                  : (isDark ? Colors.white54 : AppColors.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}

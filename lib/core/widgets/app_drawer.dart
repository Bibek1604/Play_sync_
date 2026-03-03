import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/profile/presentation/viewmodel/profile_notifier.dart';

/// Side drawer widget shown on demand from any authenticated screen.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final user = authState.user;

    // Prefer latest profile data; fall back to auth cache
    final fullName = profileState.profile?.fullName
        ?? user?.fullName
        ?? '';
    final email = profileState.profile?.email
        ?? user?.email
        ?? '';
    final avatarUrl = profileState.profile?.avatar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine the current route for active highlight
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 8,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.backgroundDark : AppColors.background).withValues(alpha: 0.95),
              border: Border(
                right: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
        children: [
          // ── Header — blue gradient ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.sidebarGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  fullName.isNotEmpty ? fullName : 'Player',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

          // ── Nav Items ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isDark: isDark,
                  isActive: currentRoute == AppRoutes.dashboard,
                  onTap: () => _navigate(context, AppRoutes.dashboard),
                ),
                _DrawerItem(
                  icon: Icons.wifi_off_rounded,
                  label: 'Offline Games',
                  isDark: isDark,
                  isActive: currentRoute == AppRoutes.offlineGames,
                  onTap: () => _navigate(context, AppRoutes.offlineGames),
                ),
                _DrawerItem(
                  icon: Icons.wifi_rounded,
                  label: 'Online Games',
                  isDark: isDark,
                  isActive: currentRoute == AppRoutes.onlineGames,
                  onTap: () => _navigate(context, AppRoutes.onlineGames),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  isDark: isDark,
                  isActive: currentRoute == AppRoutes.notifications,
                  onTap: () => _navigate(context, AppRoutes.notifications),
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isDark: isDark,
                  isActive: currentRoute == AppRoutes.profile,
                  onTap: () => _navigate(context, AppRoutes.profile),
                ),

                Divider(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  height: 24,
                ),

                // ── Logout ────────────────────────────────────────────────
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppColors.error,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (r) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final defaultColor = color ?? (isDark ? Colors.white70 : AppColors.textPrimary);
    final itemColor = isActive ? activeColor : defaultColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryLight.withValues(alpha: isDark ? 0.15 : 1.0)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: itemColor, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: itemColor,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

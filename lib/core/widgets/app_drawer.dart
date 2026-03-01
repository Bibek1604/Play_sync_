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

    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.dashboard),
                ),
                _DrawerItem(
                  icon: Icons.sports_esports_rounded,
                  label: 'Browse Games',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.game),
                ),
                _DrawerItem(
                  icon: Icons.wifi_off_rounded,
                  label: 'Offline Games',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.offlineGames),
                ),
                _DrawerItem(
                  icon: Icons.wifi_rounded,
                  label: 'Online Games',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.onlineGames),
                ),
                _DrawerItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'Leaderboard',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.rankings),
                ),
                _DrawerItem(
                  icon: Icons.history_rounded,
                  label: 'Game History',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.gameHistory),
                ),
                _DrawerItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.notifications),
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.profile),
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isDark: isDark,
                  onTap: () => _navigate(context, AppRoutes.settings),
                ),

                Divider(
                  color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                  height: 24,
                ),

                // ── Logout ────────────────────────────────────────────────
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: Colors.red,
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
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? (isDark ? AppColors.secondary : AppColors.primaryDark);
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: itemColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

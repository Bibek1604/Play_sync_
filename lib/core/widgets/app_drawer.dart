import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes/app_routes.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';

/// Side drawer widget shown on demand from any authenticated screen.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(color: cs.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
                  child: Icon(Icons.person_rounded,
                      size: 32, color: cs.onPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.fullName ?? user?.email ?? 'Gamer',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: cs.onPrimary),
                ),
                if (user?.email != null)
                  Text(
                    user!.email,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),

          // ── Nav Items ───────────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => _navigate(context, AppRoutes.dashboard),
          ),
          _DrawerItem(
            icon: Icons.sports_esports_rounded,
            label: 'Available Games',
            onTap: () => _navigate(context, AppRoutes.availableGames),
          ),
          _DrawerItem(
            icon: Icons.leaderboard_rounded,
            label: 'Rankings',
            onTap: () => _navigate(context, AppRoutes.rankings),
          ),
          _DrawerItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            onTap: () => _navigate(context, AppRoutes.chat),
          ),
          _DrawerItem(
            icon: Icons.history_rounded,
            label: 'Game History',
            onTap: () => _navigate(context, AppRoutes.gameHistory),
          ),
          _DrawerItem(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            onTap: () => _navigate(context, AppRoutes.notifications),
          ),
          _DrawerItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            onTap: () => _navigate(context, AppRoutes.profile),
          ),
          _DrawerItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () => _navigate(context, AppRoutes.settings),
          ),

          const Divider(),

          // ── Logout ──────────────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            color: theme.colorScheme.error,
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
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, route);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(label, style: TextStyle(color: effectiveColor)),
      onTap: onTap,
    );
  }
}

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../app/routes/app_routes.dart";
import "../constants/app_colors.dart";
import "../../features/auth/presentation/providers/auth_notifier.dart";
import "../../features/profile/presentation/viewmodel/profile_notifier.dart";

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final user = authState.user;

    final fullName = profileState.profile?.fullName ?? user?.fullName ?? "Gamer";
    final email = profileState.profile?.email ?? user?.email ?? "";
    final avatarUrl = profileState.profile?.avatar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? "";

    // Premium sidebar color scheme - light blue gradient theme
    final Color drawerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color headerBgStart = isDark ? const Color(0xFF3B82F6) : const Color(0xFF0EA5E9);
    final Color headerBgEnd = isDark ? const Color(0xFF1E40AF) : const Color(0xFF0284C7);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE0F2FE)],
          ),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
              blurRadius: 30,
              offset: const Offset(8, 0),
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, bottom: 24, left: 24, right: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerBgStart, headerBgEnd],
                ),
                borderRadius: const BorderRadius.only(topRight: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: avatarUrl != null
                              ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(fullName))
                              : _buildAvatarPlaceholder(fullName),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _MenuLabel(title: "🎮 GAMEPLAY", isDark: isDark),
                  _DrawerItem(icon: Icons.dashboard_customize_rounded, label: "Dashboard", isActive: currentRoute == AppRoutes.dashboard, onTap: () => _navigate(context, AppRoutes.dashboard)),
                  _DrawerItem(icon: Icons.sports_esports_rounded, label: "Active Arenas", isActive: currentRoute == AppRoutes.game, onTap: () => _navigate(context, AppRoutes.game)),
                  _DrawerItem(icon: Icons.military_tech_rounded, label: "Tournaments", isActive: currentRoute == AppRoutes.tournaments, onTap: () => _navigate(context, AppRoutes.tournaments)),
                  const SizedBox(height: 24),
                  _MenuLabel(title: "⚙️ SESSION MANAGEMENT", isDark: isDark),
                  _DrawerItem(icon: Icons.wifi_off_rounded, label: "Create Offline Game", isActive: currentRoute == AppRoutes.offlineGames, onTap: () => _navigate(context, AppRoutes.offlineGames)),
                  _DrawerItem(icon: Icons.public_rounded, label: "Create Online Game", isActive: currentRoute == AppRoutes.onlineGames, onTap: () => _navigate(context, AppRoutes.onlineGames)),
                  _DrawerItem(icon: Icons.notifications_active_rounded, label: "Notifications", isActive: currentRoute == AppRoutes.notifications, onTap: () => _navigate(context, AppRoutes.notifications)),
                  const SizedBox(height: 24),
                  _MenuLabel(title: "👤 ACCOUNT", isDark: isDark),
                  _DrawerItem(icon: Icons.person_rounded, label: "Profile Info", isActive: currentRoute == AppRoutes.profile, onTap: () => _navigate(context, AppRoutes.profile)),
                  _DrawerItem(icon: Icons.settings_rounded, label: "Preferences", isActive: currentRoute == AppRoutes.settings, onTap: () => _navigate(context, AppRoutes.settings)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _LogoutButton(onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : "G", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name != route) Navigator.pushNamed(context, route);
  }
}

class _MenuLabel extends StatelessWidget {
  final String title;
  final bool isDark;
  const _MenuLabel({required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark
              ? AppColors.textSecondaryDark.withOpacity(0.7)
              : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3B82F6).withOpacity(isDark ? 0.2 : 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1) : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isActive ? const Color(0xFF3B82F6) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              const SizedBox(width: 16),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: isActive ? FontWeight.w800 : FontWeight.w600, color: isActive ? (isDark ? Colors.white : AppColors.primary) : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary))),
              if (isActive) ...[const Spacer(), Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle))],
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(border: Border.all(color: AppColors.error.withOpacity(0.2)), borderRadius: BorderRadius.circular(16)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.logout_rounded, color: AppColors.error, size: 20), SizedBox(width: 12), Text("Sign Out Account", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15))],
        ),
      ),
    );
  }
}

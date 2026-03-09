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
    final currentRoute = ModalRoute.of(context)?.settings.name ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 285,
      child: Container(
        decoration: BoxDecoration(
          // Mixture of Sky Blue background gradient from profile
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF0F9FF)],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 32,
              offset: const Offset(6, 0),
            ),
          ],
        ),
        child: Column(
          children: [
_DrawerHeader(
              fullName: fullName,
              email: email,
              avatarUrl: avatarUrl,
              onClose: () => Navigator.pop(context),
            ),
Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _SectionLabel("NAVIGATE"),
                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: "Dashboard",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.dashboard,
                    onTap: () => _go(context, AppRoutes.dashboard),
                  ),
                  _NavItem(
                    icon: Icons.public_rounded,
                    label: "Online Games",
                    accent: const Color(0xFF0EA5E9),
                    isActive: currentRoute == AppRoutes.onlineGames,
                    onTap: () => _go(context, AppRoutes.onlineGames),
                  ),
                  _NavItem(
                    icon: Icons.location_on_rounded,
                    label: "Offline Games",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.offlineGames,
                    onTap: () => _go(context, AppRoutes.offlineGames),
                  ),
                  _NavItem(
                    icon: Icons.event_available_rounded,
                    label: "Ended Games",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.endedGames,
                    onTap: () => _go(context, AppRoutes.endedGames),
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel("ACCOUNT"),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: "My Profile",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.profile,
                    onTap: () => _go(context, AppRoutes.profile),
                  ),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: "Match History",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.gameHistory,
                    onTap: () => _go(context, AppRoutes.gameHistory),
                  ),
                  _NavItem(
                    icon: Icons.leaderboard_rounded,
                    label: "Rankings",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.rankings,
                    onTap: () => _go(context, AppRoutes.rankings),
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel("SETTINGS"),
                  _NavItem(
                    icon: Icons.notifications_rounded,
                    label: "Notifications",
                    accent: const Color(0xFF0284C7), // Unified Sky Blue theme
                    isActive: currentRoute == AppRoutes.notifications,
                    onTap: () => _go(context, AppRoutes.notifications),
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: "Settings",
                    accent: const Color(0xFF64748B),
                    isActive: currentRoute == AppRoutes.settings,
                    onTap: () => _go(context, AppRoutes.settings),
                  ),
                ],
              ),
            ),
Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              child: _LogoutButton(onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (_) => false);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  static void _go(BuildContext context, String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamed(context, route);
    }
  }
}
class _DrawerHeader extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final VoidCallback onClose;

  const _DrawerHeader({
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0284C7),
        borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
        child: Stack(
          children: [
            // Layer 1: Sky blue base gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  ),
                ),
              ),
            ),
            // Layer 2: Mixture / Dark overlay gradient matching profile
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            // Layer 3: Content
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 18,
                bottom: 20,
                left: 18,
                right: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with white border
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: avatarUrl != null && avatarUrl!.isNotEmpty
                              ? Image.network(
                                  avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarFallback(fullName),
                                )
                              : _avatarFallback(fullName),
                        ),
                      ),
                      const Spacer(),
                      // Close with translucent background
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email.isNotEmpty ? email : "Online",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.primaryLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : "G",
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: Color(0xFFB0BAC9),
        ),
      ),
    );
  }
}
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE0F2FE) : Colors.transparent, // Sky-100 pill
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF7DD3FC).withOpacity(0.4) // Sky-300
                    : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Icon tile
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFBAE6FD) // Sky-200
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: isActive ? const Color(0xFF0284C7) : const Color(0xFF94A3B8), // Sky-700 active icon
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF0284C7) // Sky-700 active text
                          : const Color(0xFF374151),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9), // Sky-500 indicator
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFECACA)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 19),
            SizedBox(width: 8),
            Text(
              "Sign Out",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../../core/widgets/app_drawer.dart";
import "../../../profile/presentation/pages/edit_profile_page.dart";
import "../../../profile/presentation/viewmodel/profile_notifier.dart";
import 'theme_preferences_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileNotifierProvider.notifier).getProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121417) : const Color(0xFFF8F9FA),
      drawer: const AppDrawer(),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_rounded, size: 20),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Settings",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D21) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: profile?.avatar != null && profile!.avatar!.isNotEmpty
                      ? NetworkImage(profile.avatar!)
                      : null,
                  child: (profile?.avatar == null || profile!.avatar!.isEmpty)
                      ? const Icon(Icons.person_rounded, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'Player',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        profile?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (profileState.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _MenuSectionHeader(title: "Account Settings", isDark: isDark),
          const SizedBox(height: 16),
          _SettingsCardTile(
            icon: Icons.person_rounded,
            title: "Edit Profile",
            subtitle: "Update your name, bio, and avatar",
            isDark: isDark,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
          ),
          const SizedBox(height: 12),
          _SettingsCardTile(
            icon: Icons.lock_rounded,
            title: "Security",
            subtitle: "Password and account protection",
            isDark: isDark,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Security settings coming soon")));
            },
          ),
          const SizedBox(height: 32),
          _MenuSectionHeader(title: "Preference", isDark: isDark),
          const SizedBox(height: 16),
          _SettingsCardTile(icon: Icons.palette_rounded, title: "Theme & Appearance", subtitle: "Dark mode and accent colors", isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemePreferencesPage()))),
          const SizedBox(height: 12),
          _SettingsCardTile(icon: Icons.notifications_active_rounded, title: "Notifications", subtitle: "Manage your alerts and pings", isDark: isDark, onTap: () {}),
          const SizedBox(height: 32),
          _MenuSectionHeader(title: "Game Experience", isDark: isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuSectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _MenuSectionHeader({required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white30 : Colors.black26, letterSpacing: 1.2)),
      ],
    );
  }
}

class _SettingsCardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  const _SettingsCardTile({required this.icon, required this.title, required this.subtitle, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D21) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.primary, size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45, fontWeight: FontWeight.w500)),
                ])),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

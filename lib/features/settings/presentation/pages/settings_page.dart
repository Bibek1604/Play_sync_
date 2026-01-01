import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

/// Settings Page
/// 
/// Main settings screen for app configuration.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _SectionHeader(title: 'Appearance', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Change app appearance',
            isDark: isDark,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.theme);
            },
          ),

          const SizedBox(height: 24),

          // Account Section
          _SectionHeader(title: 'Account', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your profile',
            isDark: isDark,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.security_outlined,
            title: 'Privacy',
            subtitle: 'Privacy settings',
            isDark: isDark,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Notification preferences',
            isDark: isDark,
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // About Section
          _SectionHeader(title: 'About', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About PlaySync',
            subtitle: 'Version 1.0.0',
            isDark: isDark,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help',
            isDark: isDark,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.secondary : AppColors.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDark ? AppColors.secondary : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        onTap: onTap,
      ),
    );
  }
}

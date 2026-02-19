import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';

/// Settings Page
///
/// Main settings screen with professional card-based design. 
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: isDark ? AppColors.backgroundPrimaryDark : AppColors.backgroundSecondaryLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.backgroundSecondaryDark : Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emerald500, AppColors.teal500],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final hPad = isTablet ? constraints.maxWidth * 0.15 : 16.0;
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
            children: [
              // Appearance Section
              _SectionHeader(title: 'Appearance', isDark: isDark),
              const SizedBox(height: 10),
              _SettingsGroup(
                isDark: isDark,
                items: [
                  _SettingsTileData(
                    icon: Icons.palette_outlined,
                    iconColor: AppColors.purple500,
                    title: 'Theme',
                    subtitle: 'Light, dark or system default',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.theme),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Account Section
              _SectionHeader(title: 'Account', isDark: isDark),
              const SizedBox(height: 10),
              _SettingsGroup(
                isDark: isDark,
                items: [
                  _SettingsTileData(
                    icon: Icons.person_outlined,
                    iconColor: AppColors.emerald500,
                    title: 'Profile',
                    subtitle: 'Edit your public profile',
                    onTap: () {},
                  ),
                  _SettingsTileData(
                    icon: Icons.security_outlined,
                    iconColor: AppColors.teal600,
                    title: 'Privacy',
                    subtitle: 'Control who sees your info',
                    onTap: () {},
                  ),
                  _SettingsTileData(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.warning,
                    title: 'Notifications',
                    subtitle: 'Push, email & in-app alerts',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // About Section
              _SectionHeader(title: 'About', isDark: isDark),
              const SizedBox(height: 10),
              _SettingsGroup(
                isDark: isDark,
                items: [
                  _SettingsTileData(
                    icon: Icons.info_outline,
                    iconColor: AppColors.info,
                    title: 'About PlaySync',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                  _SettingsTileData(
                    icon: Icons.help_outline,
                    iconColor: AppColors.emerald600,
                    title: 'Help & Support',
                    subtitle: 'FAQs, contact & feedback',
                    onTap: () {},
                  ),
                  _SettingsTileData(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.textSecondaryLight,
                    title: 'Terms & Privacy Policy',
                    subtitle: 'Legal information',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

/// Data class for a settings tile entry
class _SettingsTileData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTileData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// A grouped card containing multiple settings tiles
class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final List<_SettingsTileData> items;

  const _SettingsGroup({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDefaultDark : AppColors.borderDefaultLight,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              _SettingsTile(data: item, isDark: isDark),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: isDark ? AppColors.borderDefaultDark : AppColors.borderDefaultLight,
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Settings Tile Widget
class _SettingsTile extends StatelessWidget {
  final _SettingsTileData data;
  final bool isDark;

  const _SettingsTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

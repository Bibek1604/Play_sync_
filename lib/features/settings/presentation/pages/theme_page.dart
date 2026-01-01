import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_provider.dart';

/// Theme Page
/// 
/// Allows users to change the app theme (light/dark/system).
class ThemePage extends ConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your theme',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.secondary : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select how PlaySync looks to you',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 32),

            // Theme Options
            _ThemeOptionCard(
              icon: Icons.brightness_auto,
              iconColor: Colors.blue,
              title: 'System Default',
              subtitle: 'Follow system theme settings',
              isSelected: currentThemeMode == ThemeMode.system,
              isDark: isDark,
              onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
            ),

            const SizedBox(height: 12),

            _ThemeOptionCard(
              icon: Icons.light_mode,
              iconColor: Colors.amber[700]!,
              title: 'Light Theme',
              subtitle: 'Bright and clear appearance',
              isSelected: currentThemeMode == ThemeMode.light,
              isDark: isDark,
              onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
            ),

            const SizedBox(height: 12),

            _ThemeOptionCard(
              icon: Icons.dark_mode,
              iconColor: Colors.indigo,
              title: 'Dark Theme',
              subtitle: 'Easy on the eyes in low light',
              isSelected: currentThemeMode == ThemeMode.dark,
              isDark: isDark,
              onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
            ),

            const Spacer(),

            // Preview Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    size: 48,
                    color: isDark ? AppColors.secondary : AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current: ${isDark ? "Dark" : "Light"} Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.secondary : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme Option Card Widget
class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isDark ? AppColors.secondary : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.1)
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedColor : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? selectedColor : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

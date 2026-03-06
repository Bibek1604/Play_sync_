import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_prefs_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';

/// Simplified App Settings — Theme and Notifications only.
class AppSettingsPage extends ConsumerWidget {
  static const routeName = '/app-settings';
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final notifPrefs = ref.watch(notifPrefsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        title: Text(
          'App Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Theme Section ──────────────────────────────────────
          _SectionHeader('Appearance'),
          SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              _ThemeTile(
                icon: Icons.brightness_6_rounded,
                title: 'Theme',
                currentMode: themeMode,
                onChanged: (mode) => ref.read(themeProvider.notifier).setTheme(mode),
                isDark: isDark,
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.xl),

          // ── Notifications Section ─────────────────────────────
          _SectionHeader('Notifications'),
          SizedBox(height: AppSpacing.sm),
          _SettingsCard(
            children: [
              _NotificationToggle(
                icon: Icons.notifications_active_outlined,
                title: 'Game Invites',
                subtitle: 'Get notified when invited to a game',
                value: notifPrefs.gameInvites,
                onChanged: (_) => ref.read(notifPrefsProvider.notifier).toggle('gameInvites'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _NotificationToggle(
                icon: Icons.play_circle_outline_rounded,
                title: 'Game Starting',
                subtitle: 'Alerts when games are about to start',
                value: notifPrefs.gameStarting,
                onChanged: (_) => ref.read(notifPrefsProvider.notifier).toggle('gameStarting'),
                isDark: isDark,
              ),
              const Divider(height: 1),
              _NotificationToggle(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Messages',
                subtitle: 'New chat messages and replies',
                value: notifPrefs.chatMessages,
                onChanged: (_) => ref.read(notifPrefsProvider.notifier).toggle('chatMessages'),
                isDark: isDark,
              ),
            ],
          ),

          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: AppSpacing.xs),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textTertiary,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool isDark;

  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.currentMode,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18)),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 18)),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18)),
            ],
            selected: {currentMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              onChanged(selection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

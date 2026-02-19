import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/scorecard/presentation/providers/scorecard_state_provider.dart';
import '../../features/profile/presentation/viewmodel/profile_notifier.dart';
import '../../app/routes/app_routes.dart';
import '../theme/app_colors.dart';

/// Professional App Drawer with Greenish Theme
/// 
/// Provides navigation to:
/// - Online Games
/// - Offline Games (Nearby)
/// - Chat
/// - Player History
/// - Notifications
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final scorecardState = ref.watch(scorecardProvider);
    final scorecard = scorecardState.scorecard;
    final profileState = ref.watch(profileNotifierProvider);
    final profilePicture = profileState.profile?.profilePicture;
    
    // Load profile if not loaded
    if (profileState.profile == null && !profileState.isLoading) {
      Future.microtask(() => ref.read(profileNotifierProvider.notifier).getProfile());
    }
    // Load scorecard if not loaded
    if (scorecardState.scorecard == null && !scorecardState.isLoading) {
      Future.microtask(() => ref.read(scorecardProvider.notifier).loadScorecard());
    }
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundSecondaryDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with User Profile
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.emerald500,
                    AppColors.emerald600,
                    AppColors.teal500,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: profilePicture != null && profilePicture.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Image.network(
                                profilePicture,
                                fit: BoxFit.cover,
                                width: 74,
                                height: 74,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    user?.fullName ?? user?.email ?? 'Guest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // User Email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  const SizedBox(height: 8),
                  
                  // Points Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${scorecard?.points ?? 0} Points',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Rank Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: AppColors.warning,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rank #${scorecard?.rank ?? '-'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.videogame_asset_rounded,
                    title: 'Online Games',
                    subtitle: 'Browse all games',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.onlineGames);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.location_on_rounded,
                    title: 'Offline Games',
                    subtitle: 'Games around you',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.offlineGames);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    title: 'Player History',
                    subtitle: 'Your game records',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.gameHistory);
                    },
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    subtitle: 'Edit your profile',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'App preferences',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? AppColors.errorDark.withOpacity(0.2)
                        : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawer Item Widget
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.emerald500.withOpacity(0.1),
              AppColors.teal500.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.emerald600,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      ),
    );
  }
}



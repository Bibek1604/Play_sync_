import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/app/theme/app_colors.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';
import 'package:play_sync_new/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';
import 'package:play_sync_new/features/scorecard/presentation/providers/scorecard_state_provider.dart';

/// Profile Page - View user profile
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load profile on init
    Future.microtask(() {
      ref.read(profileNotifierProvider.notifier).getProfile();
      ref.read(scorecardProvider.notifier).loadScorecard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final scorecardState = ref.watch(scorecardProvider);
    final scorecard = scorecardState.scorecard;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null
              ? _ErrorView(
                  error: profileState.error!,
                  onRetry: () => ref.read(profileNotifierProvider.notifier).getProfile(),
                  isDark: isDark,
                )
              : profileState.profile == null
                  ? _EmptyView(isDark: isDark)
                  : RefreshIndicator(
                      onRefresh: () => ref.read(profileNotifierProvider.notifier).getProfile(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Profile Header
                              _ProfileHeader(
                                profilePicture: profileState.profile!.profilePicture,
                                fullName: profileState.profile!.fullName ?? 'No Name',
                                email: profileState.profile!.email ?? '',
                                isDark: isDark,
                              ),

                              const SizedBox(height: 24),

                              // Gaming Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatBadge(
                                      icon: Icons.emoji_events_rounded,
                                      value: '${scorecard?.points ?? 0}',
                                      label: 'Points',
                                      color: AppColors.warning,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatBadge(
                                      icon: Icons.sports_esports_rounded,
                                      value: '${scorecard?.gamesPlayed ?? 0}',
                                      label: 'Games',
                                      color: AppColors.emerald500,
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatBadge(
                                      icon: Icons.leaderboard_rounded,
                                      value: '#${scorecard?.rank ?? '-'}',
                                      label: 'Rank',
                                      color: AppColors.info,
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // Profile Info Cards
                              _InfoCard(
                                icon: Icons.phone,
                                title: 'Phone Number',
                                value: profileState.profile!.phoneNumber ?? 'Not set',
                                isDark: isDark,
                              ),

                              const SizedBox(height: 12),

                              _InfoCard(
                                icon: Icons.location_on,
                                title: 'Location',
                                value: profileState.profile!.location ?? 'Not set',
                                isDark: isDark,
                              ),

                              const SizedBox(height: 12),

                              _InfoCard(
                                icon: Icons.info_outline,
                                title: 'Bio',
                                value: profileState.profile!.bio ?? 'No bio yet',
                                isDark: isDark,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}

/// Profile Header Widget
class _ProfileHeader extends StatelessWidget {
  final String? profilePicture;
  final String fullName;
  final String email;
  final bool isDark;

  const _ProfileHeader({
    required this.profilePicture,
    required this.fullName,
    required this.email,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile Picture
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.primaryDark, AppColors.primary]
                  : [AppColors.primary, AppColors.primaryLight],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: profilePicture != null && profilePicture!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    profilePicture!,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
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
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
        ),

        const SizedBox(height: 20),

        // Name
        Text(
          fullName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),

        const SizedBox(height: 8),

        // Email
        Text(
          email,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

/// Stat Badge Widget for Profile Page
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info Card Widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;
  final int maxLines;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDefaultDark : AppColors.borderDefaultLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/// Error View
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty View
class _EmptyView extends StatelessWidget {
  final bool isDark;

  const _EmptyView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 20),
          Text(
            'No Profile Data',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

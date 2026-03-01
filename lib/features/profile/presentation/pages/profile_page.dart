import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';
import 'package:play_sync_new/features/profile/data/models/profile_response_model.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_entity.dart';
import 'package:play_sync_new/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';

/// Profile Page - View user profile
/// 
/// Pass [userId] to view another user's profile.
/// When [userId] is null, the current user's own profile is shown.
class ProfilePage extends ConsumerStatefulWidget {
  /// Optional user ID for visiting another user's profile.
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  ProfileEntity? _visitedProfile;
  bool _visitedLoading = false;
  String? _visitedError;

  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    if (_isOwnProfile) {
      Future.microtask(
          () => ref.read(profileNotifierProvider.notifier).getProfile());
    } else {
      _fetchVisitedProfile();
    }
  }

  Future<void> _fetchVisitedProfile() async {
    setState(() {
      _visitedLoading = true;
      _visitedError = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get(ApiEndpoints.getProfileById(widget.userId!));
      final model = ProfileResponseModel.fromJson(response.data);
      if (mounted) {
        setState(() {
          _visitedProfile = model.toEntity();
          _visitedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _visitedError = e.toString();
          _visitedLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Own-profile path uses the notifier; visited-profile path uses local state
    final isLoading =
        _isOwnProfile ? ref.watch(profileNotifierProvider).isLoading : _visitedLoading;
    final error =
        _isOwnProfile ? ref.watch(profileNotifierProvider).error : _visitedError;
    final profile =
        _isOwnProfile ? ref.watch(profileNotifierProvider).profile : _visitedProfile;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'Profile' : (profile?.fullName ?? 'Profile')),
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
                if (mounted) {
                  ref.read(profileNotifierProvider.notifier).getProfile();
                }
              },
            ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorView(
                  error: error,
                  onRetry: _isOwnProfile
                      ? () => ref
                          .read(profileNotifierProvider.notifier)
                          .getProfile()
                      : _fetchVisitedProfile,
                  isDark: isDark,
                )
              : profile == null
                  ? _EmptyView(isDark: isDark)
                  : RefreshIndicator(
                      onRefresh: _isOwnProfile
                          ? () => ref
                              .read(profileNotifierProvider.notifier)
                              .getProfile()
                          : () => _fetchVisitedProfile(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Profile Header
                              _ProfileHeader(
                                profile: profile,
                                isDark: isDark,
                              ),

                              const SizedBox(height: 24),

                              // XP & Level Section
                              _XpLevelCard(
                                profile: profile,
                                isDark: isDark,
                              ),

                              const SizedBox(height: 20),

                              // Stats Row
                              _StatsRow(
                                profile: profile,
                                isDark: isDark,
                              ),

                              const SizedBox(height: 24),

                              // Profile Info Cards
                              _InfoCard(
                                icon: Icons.phone,
                                title: 'Phone',
                                value: profile.phone ?? 'Not set',
                                isDark: isDark,
                              ),

                              const SizedBox(height: 12),

                              _InfoCard(
                                icon: Icons.location_on,
                                title: 'Location',
                                value: profile.place ?? 'Not set',
                                isDark: isDark,
                              ),

                              const SizedBox(height: 12),

                              _InfoCard(
                                icon: Icons.info_outline,
                                title: 'Bio',
                                value: profile.bio ?? 'No bio yet',
                                isDark: isDark,
                                maxLines: 3,
                              ),

                              const SizedBox(height: 12),

                              _InfoCard(
                                icon: Icons.sports_esports,
                                title: 'Favorite Game',
                                value: profile.favoriteGame ?? 'Not set',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}

/// XP & Level Card
class _XpLevelCard extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;

  const _XpLevelCard({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${profile.level}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${profile.xp} XP',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: profile.xpProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(profile.xpProgress * 100).toStringAsFixed(0)}% to Level ${profile.level + 1}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats Row (Games, Wins, Losses, Win Rate)
class _StatsRow extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;

  const _StatsRow({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(label: 'Games', value: '${profile.totalGames}', isDark: isDark),
        const SizedBox(width: 12),
        _StatTile(label: 'Wins', value: '${profile.wins}', isDark: isDark, color: Colors.green),
        const SizedBox(width: 12),
        _StatTile(label: 'Losses', value: '${profile.losses}', isDark: isDark, color: Colors.red),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Win Rate',
          value: '${(profile.winRate * 100).toStringAsFixed(0)}%',
          isDark: isDark,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  const _StatTile({required this.label, required this.value, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color ?? (isDark ? AppColors.secondary : AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile Header Widget
class _ProfileHeader extends StatelessWidget {
  final ProfileEntity profile;
  final bool isDark;

  const _ProfileHeader({
    required this.profile,
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
          child: profile.avatar != null && profile.avatar!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    profile.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Text(
                      profile.initials,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                )
              : Text(
                  profile.initials,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),

        const SizedBox(height: 20),

        // Name
        Text(
          profile.fullName ?? 'No Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.secondary : AppColors.primaryDark,
          ),
        ),

        const SizedBox(height: 8),

        // Email
        Text(
          profile.email ?? '',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
          ),
        ),

        if (profile.role != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.role!.toUpperCase(),
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
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
          color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
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
                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.secondary : AppColors.primaryDark,
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
              color: isDark ? Colors.red[300] : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.secondary : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
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
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Profile Data',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:play_sync_new/features/leaderboard/presentation/providers/leaderboard_notifier.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';

/// Rankings/Leaderboard Page
/// 
/// Shows user's current rank and overall leaderboard
/// Provides navigation to Games and History pages
class RankingsPage extends ConsumerStatefulWidget {
  const RankingsPage({super.key});

  @override
  ConsumerState<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends ConsumerState<RankingsPage> {
  @override
  void initState() {
    super.initState();
    // Load leaderboard on page load - All Time only
    Future.microtask(() {
      ref.read(leaderboardNotifierProvider.notifier).loadLeaderboard(
            period: 'all',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leaderboardState = ref.watch(leaderboardNotifierProvider);
    final currentUser = ref.watch(authNotifierProvider).user;

    // Find current user's rank in leaderboard
    LeaderboardEntry? userEntry;
    try {
      userEntry = leaderboardState.entries.firstWhere(
        (entry) => entry.userId == currentUser?.userId,
      );
    } catch (e) {
      userEntry = null;
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundPrimaryDark,
                    AppColors.backgroundSecondaryDark
                  ]
                : [
                    AppColors.backgroundPrimaryLight,
                    AppColors.backgroundSecondaryLight
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // User Rank Card
              if (userEntry != null) _buildUserRankCard(userEntry, isDark),

              // Quick Actions (Navigate to Games & History)
              _buildQuickActions(context, isDark),

              // Leaderboard List
              Expanded(
                child: _buildLeaderboardList(leaderboardState, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GlassCard(
      margin: AppSpacing.paddingMD,
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
              color: AppColors.emerald500,
            ),
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rankings',
                  style: AppTypography.h2,
                ),
                Text(
                  'All Time Leaderboard',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppBorderRadius.chip,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.leaderboard, size: 16, color: Colors.white),
                AppSpacing.gapHorizontalSM,
                Text(
                  'LEADERBOARD',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRankCard(dynamic userEntry, bool isDark) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rank',
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            AppSpacing.gapVerticalMD,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank Badge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userEntry.rankDisplay,
                      style: AppTypography.h1.copyWith(
                        color: Colors.white,
                        fontSize: userEntry.isTopThree ? 32 : 24,
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapHorizontalLG,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEntry.userName,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapVerticalSM,
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          AppSpacing.gapHorizontalSM,
                          Text(
                            '${userEntry.points} points',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.sports_esports,
              label: 'Available Games',
              onTap: () => Navigator.pushNamed(context, '/available-games'),
              isDark: isDark,
            ),
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: _ActionButton(
              icon: Icons.history,
              label: 'Game History',
              onTap: () => Navigator.pushNamed(context, '/game-history'),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(dynamic state, bool isDark) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: AppTypography.bodyMedium),
            AppSpacing.gapVerticalMD,
            ElevatedButton(
              onPressed: () => ref
                  .read(leaderboardNotifierProvider.notifier)
                  .loadLeaderboard(period: 'all'),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.entries.isEmpty) {
      return EmptyState(
        icon: Icons.leaderboard,
        title: 'No Rankings Yet',
        message: 'No leaderboard data available',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(leaderboardNotifierProvider.notifier).loadLeaderboard(
                period: 'all',
              ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: state.entries.length,
        itemBuilder: (context, index) {
          final entry = state.entries[index];
          return _LeaderboardTile(
            entry: entry,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

/// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Container(
          padding: AppSpacing.paddingMD,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              AppSpacing.gapVerticalSM,
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Leaderboard Tile Widget
class _LeaderboardTile extends StatelessWidget {
  final dynamic entry;
  final bool isDark;

  const _LeaderboardTile({
    required this.entry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: entry.isTopThree
                ? AppColors.primaryGradient
                : LinearGradient(
                    colors: [
                      AppColors.textPrimaryLight.withOpacity(0.1),
                      AppColors.textPrimaryLight.withOpacity(0.05),
                    ],
                  ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              entry.rankDisplay,
              style: AppTypography.h3.copyWith(
                color: entry.isTopThree
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontSize: entry.isTopThree ? 20 : 16,
              ),
            ),
          ),
        ),
        title: Text(
          entry.userName,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 16, color: AppColors.warning),
            AppSpacing.gapHorizontalSM,
            Text(
              '${entry.points}',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

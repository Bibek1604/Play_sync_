import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../game/presentation/providers/joined_games_provider.dart';
import '../../../game/presentation/providers/game_list_provider.dart';
import '../../../game/presentation/providers/offline_game_provider.dart';
import '../../../game/domain/entities/game.dart';
import '../../../game/presentation/providers/game_providers.dart';
import '../../../scorecard/presentation/providers/scorecard_state_provider.dart';
import '../../../profile/presentation/viewmodel/profile_notifier.dart';
import '../../../notifications/presentation/providers/notification_state_provider.dart';

/// Dashboard Page - Redesigned
/// 
/// Main home screen with professional greenish theme
/// Features: Online Games, Offline Games, Rankings
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load data once after the first frame, not on every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameListProvider.notifier).loadGames();
      ref.read(scorecardProvider.notifier).loadScorecard();
      ref.read(notificationProvider.notifier).loadUnreadCount();
      final profileState = ref.read(profileNotifierProvider);
      if (profileState.profile == null && !profileState.isLoading) {
        ref.read(profileNotifierProvider.notifier).getProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = authState.user;
    final profileState = ref.watch(profileNotifierProvider);
    final onlineGames = ref.watch(onlineGamesProvider);
    final offlineGames = ref.watch(offlineGamesProvider).games;
    final scorecardState = ref.watch(scorecardProvider);
    final scorecard = scorecardState.scorecard;
    final profilePicture = profileState.profile?.profilePicture;
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.emerald500, AppColors.teal500],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'PlaySync',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_rounded,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final hPad = isTablet ? constraints.maxWidth * 0.08 : 20.0;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Banner Section
                    _NotificationBanner(isDark: isDark),
                    
                    const SizedBox(height: 20),

                    // Welcome Section with User Info
                    _WelcomeCard(
                      userName: user?.fullName ?? user?.email ?? 'Gamer',
                      points: scorecard?.points ?? 0,
                      gamesJoined: scorecard?.gamesPlayed ?? 0,
                      profileUrl: profilePicture,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Main Action Buttons Title
                    Text(
                      'Play Now',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your game mode',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isTablet) ...[  
                      // Tablet: 2-column grid for action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _MainActionButton(
                              icon: Icons.public_rounded,
                              title: 'Online Games',
                              subtitle: '${onlineGames.length} active games',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.emerald500, AppColors.emerald600],
                              ),
                              isDark: isDark,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MainActionButton(
                              icon: Icons.location_on_rounded,
                              title: 'Offline Games',
                              subtitle: '${offlineGames.length} local games',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.teal500, AppColors.teal600],
                              ),
                              isDark: isDark,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.offlineGames),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MainActionButton(
                        icon: Icons.leaderboard_rounded,
                        title: 'Rankings',
                        subtitle: 'View player leaderboard & your rank',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.purple500, AppColors.purple600],
                        ),
                        isDark: isDark,
                        badgeText: 'TOP 10',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.rankings),
                      ),
                    ] else ...[
                      // Mobile: Single-column buttons
                      _MainActionButton(
                        icon: Icons.public_rounded,
                        title: 'Online Games',
                        subtitle: '${onlineGames.length} active games',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.emerald500, AppColors.emerald600],
                        ),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
                      ),
                      const SizedBox(height: 16),
                      _MainActionButton(
                        icon: Icons.location_on_rounded,
                        title: 'Offline Games',
                        subtitle: '${offlineGames.length} local games',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.teal500, AppColors.teal600],
                        ),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.offlineGames),
                      ),
                      const SizedBox(height: 16),
                      _MainActionButton(
                        icon: Icons.leaderboard_rounded,
                        title: 'Rankings',
                        subtitle: 'View player leaderboard & your rank',
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.purple500, AppColors.purple600],
                        ),
                        isDark: isDark,
                        badgeText: 'TOP 10',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.rankings),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // My Joined Games Section
                    _MyJoinedGamesSection(
                      userId: user?.userId,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 32),

                    // Quick Stats Section
                    Text(
                      'Your Stats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your gaming progress',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.games_rounded,
                            value: '${scorecard?.gamesPlayed ?? 0}',
                            label: 'Games Joined',
                            color: AppColors.emerald500,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.emoji_events_rounded,
                            value: '${scorecard?.points ?? 0}',
                            label: 'Total Points',
                            color: AppColors.warning,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.leaderboard_rounded,
                            value: scorecard?.rank != null ? '#${scorecard!.rank}' : '-',
                            label: 'Rank',
                            color: AppColors.purple500,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Welcome Card Widget - Redesigned
class _WelcomeCard extends ConsumerWidget {
  final String userName;
  final int points;
  final int gamesJoined;
  final String? profileUrl;
  final bool isDark;

  const _WelcomeCard({
    required this.userName,
    required this.points,
    required this.gamesJoined,
    this.profileUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald500.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                ),
                child: profileUrl != null && profileUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          profileUrl!,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Points and Games Joined Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Points',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$gamesJoined',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Games',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Builder(builder: (context) {
                final socketService = ref.watch(socketServiceProvider);
                final isOnline = socketService.isConnected;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: isOnline ? const Color(0xFF69F0AE) : Colors.grey,
                        size: 10,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// Main Action Button Widget
class _MainActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final bool isDark;
  final String? badgeText;
  final VoidCallback onTap;

  const _MainActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.isDark,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient.colors.first).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundSecondaryDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification Banner Widget - shown at top of dashboard
class _NotificationBanner extends ConsumerWidget {
  final bool isDark;

  const _NotificationBanner({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));

    // Hide the banner when there are no unread notifications
    if (unreadCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark
                ? [
                    AppColors.emerald600.withOpacity(0.25),
                    AppColors.teal600.withOpacity(0.25),
                  ]
                : [
                    AppColors.emerald500.withOpacity(0.08),
                    AppColors.teal500.withOpacity(0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.emerald500.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    color: AppColors.emerald600,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundPrimaryDark
                            : AppColors.backgroundSecondaryLight,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unreadCount == 1
                        ? '1 new notification'
                        : '$unreadCount new notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to see invites, game updates & more',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.emerald600,
            ),
          ],
        ),
      ),
    );
  }
}

/// My Joined Games Section Widget
class _MyJoinedGamesSection extends ConsumerStatefulWidget {
  final String? userId;
  final bool isDark;

  const _MyJoinedGamesSection({
    required this.userId,
    required this.isDark,
  });

  @override
  ConsumerState<_MyJoinedGamesSection> createState() => _MyJoinedGamesSectionState();
}

class _MyJoinedGamesSectionState extends ConsumerState<_MyJoinedGamesSection> {
  @override
  void initState() {
    super.initState();
    // Load joined games when widget initializes
    Future.microtask(() {
      ref.read(joinedGamesProvider.notifier).loadJoinedGames();
    });
  }

  Future<void> _confirmLeaveGame(BuildContext context, String gameId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Call leave game API
        await ref.read(leaveGameUseCaseProvider).call(gameId);
        
        // Refresh joined games
        await ref.read(joinedGamesProvider.notifier).loadJoinedGames();

        if (mounted) {
          // Hide loading
          Navigator.pop(context); 
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have left the game'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave game: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinedGamesState = ref.watch(joinedGamesProvider);
    
    // Show loading indicator while fetching
    if (joinedGamesState.isLoading && joinedGamesState.games.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if any
    if (joinedGamesState.error != null && joinedGamesState.games.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load your games',
              style: TextStyle(
                color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: () => ref.read(joinedGamesProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    // Show empty state if no joined games
    if (joinedGamesState.games.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Games',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.backgroundSecondaryDark.withOpacity(0.4)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.sports_esports_outlined,
                  size: 52,
                  color: widget.isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'No active games',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join a game to see it here',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final joinedGames = joinedGamesState.games;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Games',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            if (joinedGames.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.gameHistory);
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Games you have joined',
          style: TextStyle(
            fontSize: 14,
            color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
        ...joinedGames.take(3).map((game) {
          final isActive = game.status == GameStatus.open ||
              game.status == GameStatus.full;
          return _JoinedGameCard(
            game: game,
            isDark: widget.isDark,
            onTap: () {
              // Navigate to chat for this game
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: {'gameId': game.id},
              );
            },
            onLeave: isActive ? () => _confirmLeaveGame(context, game.id) : null,
          );
        }).toList(),
      ],
    );
  }
}

/// Joined Game Card Widget
class _JoinedGameCard extends StatelessWidget {
  final Game game;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLeave;

  const _JoinedGameCard({
    required this.game,
    required this.isDark,
    required this.onTap,
    this.onLeave,
  });

  Color _getStatusColor() {
    switch (game.status) {
      case GameStatus.open:
        return AppColors.success;
      case GameStatus.full:
        return AppColors.info;
      case GameStatus.ended:
        return AppColors.error;
      case GameStatus.cancelled:
        return AppColors.warning;
    }
  }

  String _getStatusText() {
    switch (game.status) {
      case GameStatus.open:
        return 'Open';
      case GameStatus.full:
        return 'Full';
      case GameStatus.ended:
        return 'Ended';
      case GameStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get _isFinished =>
      game.status == GameStatus.ended || game.status == GameStatus.cancelled;

  @override
  Widget build(BuildContext context) {
    final finished = _isFinished;
    final statusColor = _getStatusColor();

    return Opacity(
      opacity: finished ? 0.72 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundSecondaryDark.withOpacity(finished ? 0.3 : 0.5)
              : (finished ? const Color(0xFFF5F5F5) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: finished
                ? statusColor.withOpacity(0.35)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
            width: finished ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: finished ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Game icon — greyed for finished
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: finished
                          ? const LinearGradient(
                              colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)])
                          : LinearGradient(
                              colors: [AppColors.emerald500, AppColors.teal500]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      finished ? Icons.sports_esports_outlined : Icons.sports_esports,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Game details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: finished
                                ? (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                            decoration:
                                finished ? TextDecoration.lineThrough : null,
                            decorationColor: statusColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.currentPlayers}/${game.maxPlayers}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: finished
                                    ? Border.all(
                                        color: statusColor.withOpacity(0.4),
                                        width: 1)
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (finished)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        game.status == GameStatus.ended
                                            ? Icons.check_circle_outline
                                            : Icons.cancel_outlined,
                                        size: 12,
                                        color: statusColor,
                                      ),
                                    ),
                                  Text(
                                    _getStatusText(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Trailing action
                  if (onLeave != null)
                    IconButton(
                      icon: const Icon(
                        Icons.exit_to_app_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: onLeave,
                      tooltip: 'Leave Game',
                    )
                  else if (!finished)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )
                  else
                    // Finished indicator pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        game.status == GameStatus.ended ? 'Done' : 'Cancelled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



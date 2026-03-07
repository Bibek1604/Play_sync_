import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/app/routes/app_routes.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "package:play_sync_new/core/widgets/app_drawer.dart";
import "package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart";
import "package:play_sync_new/features/dashboard/presentation/widgets/game_tile_widget.dart";
import "package:play_sync_new/features/game/domain/entities/game_entity.dart";
import "package:play_sync_new/features/game/presentation/providers/game_notifier.dart";
import "package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart";

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(profileNotifierProvider.notifier).getProfile();
      await ref.read(gameProvider.notifier).fetchMyCreatedGames();
      await ref.read(gameProvider.notifier).fetchMyJoinedGames();
      // Fetch available games (exclude games user created/joined)
      await ref.read(gameProvider.notifier).fetchGames(refresh: true, excludeMe: true);
    });
  }

  Future<void> _refresh() async {
    await ref.read(profileNotifierProvider.notifier).getProfile();
    await ref.read(gameProvider.notifier).fetchMyCreatedGames();
    await ref.read(gameProvider.notifier).fetchMyJoinedGames();
    // Fetch available games
    await ref.read(gameProvider.notifier).fetchGames(refresh: true, excludeMe: true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final gameState = ref.watch(gameProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authState.user;
    final profile = profileState.profile;

    final String displayName = profile?.fullName ?? user?.fullName ?? "Gamer";
    final String? currentUserId = user?.userId ?? profile?.userId;
    // Setup light bluish-white radial/linear background for light mode
    final bgColor1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final bgColor2 = isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFBAE6FD), Colors.white], // Sky blue tint matching bottom bar
            stops: const [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // Minimal App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF0284C7), size: 28),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF0284C7), size: 26),
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Dashboard Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greetings
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Profile Details Card
                        _ProfileDetailsCard(
                          totalGames: profile?.totalGames ?? 0,
                          wins: profile?.wins ?? 0,
                          winRate: (profile?.winRate ?? 0).toDouble(),
                          isDark: isDark,
                        ),
                        
                        const SizedBox(height: 28),

                        // 3 Action Cards
                        Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _ActionCard(icon: Icons.wifi_off_rounded, title: "Offline", color: AppColors.primary, onTap: () => Navigator.pushNamed(context, AppRoutes.offlineGames), isDark: isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _ActionCard(icon: Icons.public_rounded, title: "Online", color: AppColors.secondary, onTap: () => Navigator.pushNamed(context, AppRoutes.onlineGames), isDark: isDark)),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const SizedBox(height: 48), // Gap above Created section
                        
                        // Games I Created Section
                        _GamesSection(
                          title: "🎮 Games I Created",
                          games: gameState.myCreatedGames,
                          isLoading: gameState.isLoading && gameState.myCreatedGames.isEmpty,
                          emptyText: "You haven't created any games yet",
                          currentUserId: currentUserId,
                          isCreatorSection: true,
                        ),
                        const SizedBox(height: 48), // Gap above Joined section
                        
                        // Games I Joined Section
                        _GamesSection(
                          title: "🏆 Games I Joined",
                          games: gameState.myJoinedGames.where((game) => game.isParticipant(currentUserId ?? '')).toList(),
                          isLoading: gameState.isLoading && gameState.myJoinedGames.isEmpty,
                          emptyText: "You haven't joined any games yet",
                          currentUserId: currentUserId,
                          isCreatorSection: false,
                        ),
                        
                        const SizedBox(height: 32),

                        // Browse Navigation Buttons

                        const SizedBox(height: 40),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  final int totalGames;
  final int wins;
  final double winRate;
  final bool isDark;

  const _ProfileDetailsCard({
    required this.totalGames,
    required this.wins,
    required this.winRate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle top-right accent gradient
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Performance Summary",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              "Real-time gaming statistics",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatBadge(label: "Played", value: totalGames.toString(), icon: Icons.sports_esports_rounded, color: AppColors.primary, isDark: isDark)),
                      _VerticalDivider(isDark: isDark),
                      Expanded(child: _StatBadge(label: "Wins", value: wins.toString(), icon: Icons.emoji_events_rounded, color: const Color(0xFFF59E0B), isDark: isDark)),
                      _VerticalDivider(isDark: isDark),
                      Expanded(child: _StatBadge(label: "Win Rate", value: "${winRate.toInt()}%", icon: Icons.bolt_rounded, color: const Color(0xFF10B981), isDark: isDark)),
                    ],
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

class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBadge({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [color.withOpacity(0.2), color.withOpacity(0.05)]
                : [color.withOpacity(0.12), color.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? color.withOpacity(0.15) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesSection extends StatelessWidget {
  final String title;
  final List<GameEntity> games;
  final bool isLoading;
  final String emptyText;
  final String? currentUserId;
  final bool isCreatorSection;

  const _GamesSection({
    required this.title,
    required this.games,
    required this.isLoading,
    required this.emptyText,
    required this.currentUserId,
    required this.isCreatorSection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.gamepad_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (games.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.videogame_asset_off_rounded, size: 40, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text(
                  emptyText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 280, // Increased to 280 to resolve the 2.1px bottom overflow
child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return Padding(
                  padding: EdgeInsets.only(right: 16, left: index == 0 ? 4 : 0, bottom: 8),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.65, // Reduced width for better balance
                    child: GameTileWidget(
                      game: game,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}



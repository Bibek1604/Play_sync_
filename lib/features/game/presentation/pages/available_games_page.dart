import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_list_provider.dart';
import 'package:play_sync_new/features/game/presentation/providers/nearby_games_notifier.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';

/// Available Games Page
/// 
/// Shows available games categorized into:
/// - Online: All available games from server
/// - Offline: Nearby games based on location
class AvailableGamesPage extends ConsumerStatefulWidget {
  const AvailableGamesPage({super.key});

  @override
  ConsumerState<AvailableGamesPage> createState() =>
      _AvailableGamesPageState();
}

class _AvailableGamesPageState extends ConsumerState<AvailableGamesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load both online and offline games
    Future.microtask(() {
      ref.read(gameListProvider.notifier).loadGames();
      ref.read(nearbyGamesNotifierProvider.notifier).loadNearbyGames();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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

              // Tab Bar
              _buildTabBar(isDark),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOnlineGamesTab(isDark),
                    _buildOfflineGamesTab(isDark),
                  ],
                ),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.emerald500,
          ),
          AppSpacing.gapHorizontalMD,
          const Expanded(
            child: Text(
              'Available Games',
              style: AppTypography.h2,
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
                const Icon(Icons.sports_esports, size: 16, color: Colors.white),
                AppSpacing.gapHorizontalSM,
                Text(
                  'GAMES',
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

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: AppBorderRadius.radiusLG,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppBorderRadius.radiusLG,
        ),
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? Colors.white70 : Colors.black54,
        labelStyle: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.cloud),
            text: 'Online',
          ),
          Tab(
            icon: Icon(Icons.location_on),
            text: 'Nearby',
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineGamesTab(bool isDark) {
    final gameListState = ref.watch(gameListProvider);

    if (gameListState.isLoading && gameListState.games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gameListState.error != null && gameListState.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            AppSpacing.gapVerticalMD,
            Text(
              gameListState.error!,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton(
              onPressed: () => ref.read(gameListProvider.notifier).loadGames(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (gameListState.games.isEmpty) {
      return EmptyState(
        icon: Icons.sports_esports,
        title: 'No online games available',
        message: 'Check back later or create a new game',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gameListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: gameListState.games.length,
        itemBuilder: (context, index) {
          return _GameCard(
            game: gameListState.games[index],
            isDark: isDark,
            showDistance: false,
          );
        },
      ),
    );
  }

  Widget _buildOfflineGamesTab(bool isDark) {
    final nearbyState = ref.watch(nearbyGamesNotifierProvider);

    if (nearbyState.isLoading && nearbyState.games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (nearbyState.error != null && nearbyState.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            AppSpacing.gapVerticalMD,
            Text(
              nearbyState.error!,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton(
              onPressed: () =>
                  ref.read(nearbyGamesNotifierProvider.notifier).loadNearbyGames(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (nearbyState.games.isEmpty) {
      return EmptyState(
        icon: Icons.location_off,
        title: 'No nearby games found',
        message: 'Try expanding your search radius or going online',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(nearbyGamesNotifierProvider.notifier).loadNearbyGames(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: nearbyState.games.length,
        itemBuilder: (context, index) {
          return _GameCard(
            game: nearbyState.games[index],
            isDark: isDark,
            showDistance: true,
          );
        },
      ),
    );
  }
}

/// Game Card Widget
class _GameCard extends StatelessWidget {
  final Game game;
  final bool isDark;
  final bool showDistance;

  const _GameCard({
    required this.game,
    required this.isDark,
    this.showDistance = false,
  });

  Color _getStatusColor() {
    switch (game.status) {
      case GameStatus.open:
        return AppColors.success;
      case GameStatus.full:
        return AppColors.warning;
      case GameStatus.ended:
        return AppColors.textSecondaryLight;
      case GameStatus.cancelled:
        return AppColors.error;
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

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () {
          // Navigate to game lobby
          Navigator.pushNamed(
            context,
            '/game-lobby',
            arguments: game.id,
          );        },
        borderRadius: AppBorderRadius.radiusLG,
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      game.name,
                      style: AppTypography.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: AppBorderRadius.radiusSM,
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: AppTypography.caption.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapVerticalMD,
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  AppSpacing.gapHorizontalSM,
                  Text(
                    '${game.players.length}/${game.maxPlayers} players',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (showDistance && game.latitude != null) ...[
                    AppSpacing.gapHorizontalMD,
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      '${(game.maxDistance ?? 0).toStringAsFixed(1)} km',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (game.isFull) ...[
                AppSpacing.gapVerticalSM,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: AppBorderRadius.radiusSM,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.block,
                        size: 14,
                        color: AppColors.error,
                      ),
                      AppSpacing.gapHorizontalSM,
                      Text(
                        'Game Full',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

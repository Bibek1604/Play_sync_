import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_list_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/create_game_dialog.dart';
import 'package:play_sync_new/features/game/presentation/widgets/game_card.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:play_sync_new/app/routes/app_routes.dart';

/// Online Games Page
/// 
/// Shows all available online games with:
/// - Games list with search and filters
/// - Create game FAB
/// - Join game functionality with redirect to chat
class OnlineGamesPage extends ConsumerStatefulWidget {
  const OnlineGamesPage({super.key});

  @override
  ConsumerState<OnlineGamesPage> createState() => _OnlineGamesPageState();
}

class _OnlineGamesPageState extends ConsumerState<OnlineGamesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load games on page load
    Future.microtask(() {
      ref.read(gameListProvider.notifier).loadGames();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gamesState = ref.watch(gameListProvider);

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

              // Search Bar
              _buildSearchBar(isDark),

              // Games List
              Expanded(
                child: _buildGamesList(gamesState, isDark),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
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
            ),
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Games',
                  style: AppTypography.h2,
                ),
                Text(
                  'Join or create a game',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(gameListProvider.notifier).loadGames();
            },
            icon: const Icon(Icons.refresh),
          ),
          // ── Create Game button (top-right) ──────────────────────────
          Tooltip(
            message: 'Create a new game',
            child: ElevatedButton.icon(
              onPressed: () => _showCreateGameDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: AppSpacing.paddingHorizontalMD,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search games...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? AppColors.backgroundSecondaryDark.withOpacity(0.5)
              : Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGamesList(GameListState state, bool isDark) {
    if (state.isLoading && state.games.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            AppSpacing.gapVerticalMD,
            Text(
              'Failed to load games',
              style: AppTypography.h3,
            ),
            AppSpacing.gapVerticalSM,
            Text(
              state.error!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalMD,
            ElevatedButton.icon(
              onPressed: () {
                ref.read(gameListProvider.notifier).loadGames();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 64,
              color: Colors.grey,
            ),
            AppSpacing.gapVerticalMD,
            Text(
              'No games available',
              style: AppTypography.h3,
            ),
            AppSpacing.gapVerticalSM,
            Text(
              'Be the first to create a game!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // Filter games based on search and category
    final filteredGames = state.games.where((game) {
      // Only show online games
      if (game.category != GameCategory.online) return false;
      
      if (_searchQuery.isEmpty) return true;
      return game.title.toLowerCase().contains(_searchQuery);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gameListProvider.notifier).loadGames();
      },
      child: ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: filteredGames.length,
        itemBuilder: (context, index) {
          final game = filteredGames[index];
          final currentUserId = ref.read(currentUserIdProvider);
          return GameCard(
            game: game,
            currentUserId: currentUserId,
            onTap: () => _handleGameTap(game),
            onJoin: () => _handleJoinGame(game),
            onDelete: () => _handleDeleteGame(game),
            onChat: () => _navigateToChat(game.id),
          );
        },
      ),
    );
  }

  void _handleGameTap(Game game) {
    _navigateToChat(game.id);
  }

  void _navigateToChat(String gameId) {
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {'gameId': gameId},
    );
  }

  Future<void> _handleDeleteGame(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Game'),
          ],
        ),
        content: Text('Are you sure you want to delete "${game.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(gameListProvider.notifier).deleteGame(game.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${game.title}" deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleJoinGame(Game game) async {
    // Check if game is full before attempting to join
    if (game.isFull) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Game Full'),
            ],
          ),
          content: Text(
            'Sorry, "${game.title}" is currently full. Please try another game.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Join the game
      await ref.read(gameListProvider.notifier).joinGame(game.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to chat after joining
      if (mounted) {
        _navigateToChat(game.id);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${game.title}!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Check if error is about game being full
      final errorMessage = e.toString();
      if (errorMessage.contains('Game is full')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Game Full'),
              ],
            ),
            content: Text(
              'Sorry, "${game.title}" is currently full. Please try another game.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Show generic error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join game: $errorMessage'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCreateGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateGameDialog(
        onGameCreated: (gameId) {
          // The list is already refreshed inside createGame method
          // Navigate to chat for the created game
          Navigator.pushNamed(
            context,
            AppRoutes.chat,
            arguments: {'gameId': gameId},
          );
        },
      ),
    );
  }
}

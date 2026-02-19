import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_list_provider.dart';
import 'package:play_sync_new/features/game/presentation/providers/current_game_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/game_card.dart';
import 'package:play_sync_new/features/game/presentation/widgets/create_game_dialog.dart';
import 'package:play_sync_new/features/game/presentation/screens/game_hub_screen.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';

/// Game Lobby Screen
/// 
/// Shows list of available games to join
class GameLobbyScreen extends ConsumerStatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  @override
  void initState() {
    super.initState();
    // Load games on init
    Future.microtask(() => ref.read(gameListProvider.notifier).loadGames());
  }

  @override
  Widget build(BuildContext context) {
    final gameListState = ref.watch(gameListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.backgroundPrimaryDark, AppColors.backgroundSecondaryDark]
                : [AppColors.backgroundPrimaryLight, AppColors.backgroundSecondaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Games List
              Expanded(
                child: _buildGamesList(gameListState),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGame(context),
        backgroundColor: AppColors.emerald500,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'CREATE GAME',
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLG,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Lobby',
                  style: AppTypography.h1,
                ),
                AppSpacing.gapVerticalSM,
                Text(
                  'Join or create a game session',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(gameListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            color: AppColors.emerald500,
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(GameListState state) {
    if (state.isLoading && state.games.isEmpty) {
      return ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: 5,
        itemBuilder: (context, index) => const CardShimmer(),
      );
    }

    if (state.error != null) {
      return ErrorState(
        message: state.error,
        onRetry: () => ref.read(gameListProvider.notifier).loadGames(),
      );
    }

    if (state.games.isEmpty) {
      return EmptyState(
        icon: Icons.gamepad_outlined,
        title: 'No Games Available',
        message: 'Create a new game to get started',
        actionLabel: 'Create Game',
        onAction: () => _navigateToCreateGame(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gameListProvider.notifier).refresh(),
      color: AppColors.emerald500,
      child: ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: state.games.length,
        itemBuilder: (context, index) {
          final game = state.games[index];
          return GameCard(
            game: game,
            onTap: () => _joinGame(game.id),
          );
        },
      ),
    );
  }

  Future<void> _joinGame(String gameId) async {
    try {
      await ref.read(currentGameProvider.notifier).joinGame(gameId);
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GameHubScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, e.toString());
      }
    }
  }

  void _navigateToCreateGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateGameDialog(
        onGameCreated: (gameId) {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import 'game_detail_page.dart';

/// Displays all available (open) games regardless of category.
class AvailableGamesPage extends ConsumerWidget {
  const AvailableGamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final currentUserId = ref.watch(authNotifierProvider).user?.userId;
    final openGames = state.games.where((g) => g.status == GameStatus.OPEN).toList();

    Future<void> doAction(
      Future<bool> Function() action,
      String successMsg,
      String failKey,
    ) async {
      final ok = await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? successMsg : (ref.read(gameProvider).error ?? failKey)),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Available Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(gameProvider.notifier).fetchGames(refresh: true),
          ),
        ],
      ),
      body: _GameList(
        games: openGames,
        currentUserId: currentUserId,
        isLoading: state.isLoading,
        error: state.error,
        onRefresh: () =>
            ref.read(gameProvider.notifier).fetchGames(refresh: true),
        onJoin: (gameId) => doAction(
          () => ref.read(gameProvider.notifier).joinGame(gameId),
          'Joined game!',
          'Failed to join',
        ),
        onLeave: (gameId) => doAction(
          () => ref.read(gameProvider.notifier).leaveGame(gameId),
          'Left game',
          'Failed to leave',
        ),
        onTap: (game) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameDetailPage(
              gameId: game.id,
              preloadedGame: game,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable scrollable game list with empty-state and error handling.
class _GameList extends StatelessWidget {
  const _GameList({
    required this.games,
    required this.currentUserId,
    required this.isLoading,
    required this.onRefresh,
    required this.onJoin,
    required this.onLeave,
    required this.onTap,
    this.error,
  });

  final List<GameEntity> games;
  final String? currentUserId;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(String gameId) onJoin;
  final void Function(String gameId) onLeave;
  final void Function(GameEntity game) onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading && games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && games.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 8),
          Text(error!),
          TextButton(
              onPressed: onRefresh, child: const Text('Retry')),
        ]),
      );
    }
    if (games.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sports_esports, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text('No games found'),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: games.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final game = games[i];
          return GameCard(
            game: game,
            currentUserId: currentUserId,
            onTap: () => onTap(game),
            onJoin: () => onJoin(game.id),
            onLeave: () => onLeave(game.id),
          );
        },
      ),
    );
  }
}

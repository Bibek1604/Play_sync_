import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';

/// Displays all available (open) games regardless of category.
class AvailableGamesPage extends ConsumerWidget {
  const AvailableGamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);

    return Scaffold(
      appBar: AppBar(
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
        games: state.games
            .where((g) => g.status == GameStatus.upcoming)
            .toList(),
        isLoading: state.isLoading,
        error: state.error,
        onRefresh: () =>
            ref.read(gameProvider.notifier).fetchGames(refresh: true),
      ),
    );
  }
}

/// Reusable scrollable game list with empty-state and error handling.
class _GameList extends StatelessWidget {
  const _GameList({
    required this.games,
    required this.isLoading,
    required this.onRefresh,
    this.error,
  });

  final List games;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading && games.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && games.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
          const Icon(Icons.sports_esports, size: 64, color: Colors.grey),
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
        itemBuilder: (_, i) => GameCard(game: games[i]),
      ),
    );
  }
}

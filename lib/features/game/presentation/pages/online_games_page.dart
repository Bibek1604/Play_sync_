import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';

/// Online games page — shows only games with [isOnline == true].
class OnlineGamesPage extends ConsumerWidget {
  const OnlineGamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final onlineGames =
        state.games.where((g) => g.isOnline).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(gameProvider.notifier).fetchGames(refresh: true),
          ),
        ],
      ),
      body: state.isLoading && onlineGames.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : onlineGames.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No online games available'),
                    TextButton(
                      onPressed: () => ref
                          .read(gameProvider.notifier)
                          .fetchGames(refresh: true),
                      child: const Text('Refresh'),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(gameProvider.notifier)
                      .fetchGames(refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: onlineGames.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => GameCard(game: onlineGames[i]),
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../profile/presentation/viewmodel/profile_notifier.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import 'game_detail_page.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';

/// Displays all available (open) games regardless of category.
class AvailableGamesPage extends ConsumerStatefulWidget {
  const AvailableGamesPage({super.key});

  @override
  ConsumerState<AvailableGamesPage> createState() => _AvailableGamesPageState();
}

class _AvailableGamesPageState extends ConsumerState<AvailableGamesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).setCategoryFilter(null);
      ref.read(gameProvider.notifier).fetchGames(refresh: true, excludeMe: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final currentUserId = ref.watch(authNotifierProvider).user?.userId;
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;
    final openGames = state.availableGames.where((g) => g.status == GameStatus.OPEN).toList();
    final createdGameIds = <String>{...state.myCreatedGames.map((g) => g.id)};

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
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: profile?.avatar != null && profile!.avatar!.isNotEmpty
                  ? NetworkImage(profile.avatar!)
                  : null,
              child: profile?.avatar == null || profile!.avatar!.isEmpty
                  ? Text(
                      profile?.fullName?.isNotEmpty == true
                          ? profile!.fullName![0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            const Text('Available Games'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(gameProvider.notifier).fetchGames(refresh: true, excludeMe: true),
          ),
        ],
      ),
      body: _GameList(
        games: openGames,
        currentUserId: currentUserId,
        createdGameIds: createdGameIds,
        isLoading: state.isLoading,
        error: state.error,
        onRefresh: () =>
            ref.read(gameProvider.notifier).fetchGames(refresh: true, excludeMe: true),
        onJoin: (gameId) => doAction(
          () async {
            final result = await ref.read(gameProvider.notifier).joinGame(gameId);
            return result != null;
          },
          'Joined game!',
          'Failed to join',
        ),
        onLeave: (gameId) => doAction(
          () async {
            final result = await ref.read(gameProvider.notifier).leaveGame(gameId);
            if (result != null) ref.read(chatProvider.notifier).leaveRoom(gameId);
            return result != null;
          },
          'Left game',
          'Failed to leave',
        ),
        onCancel: (gameId) => doAction(
          () async {
            final result = await ref.read(gameProvider.notifier).cancelGame(gameId);
            return result != null;
          },
          'Game cancelled',
          'Failed to cancel',
        ),
        onDelete: (gameId) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Game'),
              content: const Text(
                  'Are you sure you want to permanently delete this game? This cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await doAction(
              () => ref.read(gameProvider.notifier).deleteGame(gameId),
              'Game deleted',
              'Failed to delete',
            );
          }
        },
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
    required this.createdGameIds,
    required this.isLoading,
    required this.onRefresh,
    required this.onJoin,
    required this.onLeave,
    required this.onCancel,
    required this.onDelete,
    required this.onTap,
    this.error,
  });

  final List<GameEntity> games;
  final String? currentUserId;
  final Set<String> createdGameIds;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(String gameId) onJoin;
  final void Function(String gameId) onLeave;
  final void Function(String gameId) onCancel;
  final void Function(String gameId) onDelete;
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
            isAlreadyCreator: currentUserId != null &&
                createdGameIds.contains(game.id),
            onTap: () => onTap(game),
            onJoin: () => onJoin(game.id),
            onLeave: () => onLeave(game.id),
            onCancel: () => onCancel(game.id),
            onDelete: () => onDelete(game.id),
          );
        },
      ),
    );
  }
}

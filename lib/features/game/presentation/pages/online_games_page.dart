import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../widgets/create_game_sheet.dart';
import '../../domain/entities/game_entity.dart';
import 'game_detail_page.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';

class OnlineGamesPage extends ConsumerStatefulWidget {
  const OnlineGamesPage({super.key});

  @override
  ConsumerState<OnlineGamesPage> createState() => _OnlineGamesPageState();
}

class _OnlineGamesPageState extends ConsumerState<OnlineGamesPage> {
  @override
  void initState() {
    super.initState();
    // Load joined/created game lists so we can detect already-joined games
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).setCategoryFilter('ONLINE');
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateGameSheet(isOnlineMode: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.userId;
    final onlineGames = () {
      final Set<String> allIds = {};
      final list = <GameEntity>[];
      for (final g in state.filteredGames) {
        if (!allIds.contains(g.id)) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      for (final g in state.myCreatedGames) {
        if (g.category == 'ONLINE' && !allIds.contains(g.id)) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      for (final g in state.myJoinedGames) {
        if (g.category == 'ONLINE' && !allIds.contains(g.id)) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      return list;
    }();

    // Build a set of joined + created game IDs for quick lookup
    final joinedGameIds = <String>{
      ...state.myJoinedGames.map((g) => g.id),
      ...state.myCreatedGames.map((g) => g.id),
    };
    final createdGameIds = <String>{...state.myCreatedGames.map((g) => g.id)};

    Future<void> doAction(Future<bool> Function() action, String successMsg,
        String failKey) async {
      final ok = await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? successMsg
              : (ref.read(gameProvider).error ?? failKey)),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    Future<void> confirmDelete(String gameId) async {
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
          'Failed to delete game',
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        title: Text('Online Games',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () async {
              await Future.wait([
                ref.read(gameProvider.notifier).fetchGames(refresh: true),
                ref.read(gameProvider.notifier).fetchMyJoinedGames(),
                ref.read(gameProvider.notifier).fetchMyCreatedGames(),
              ]);
            },
          ),
        ],
      ),
      body: state.isLoading && onlineGames.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary))
          : onlineGames.isEmpty
              ? _EmptyState(onCreateTap: () => _showCreateSheet(context))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await Future.wait([
                      ref.read(gameProvider.notifier).fetchGames(refresh: true),
                      ref.read(gameProvider.notifier).fetchMyJoinedGames(),
                      ref.read(gameProvider.notifier).fetchMyCreatedGames(),
                    ]);
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: onlineGames.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final game = onlineGames[i];
                      // A user is "joined" if they appear in myJoinedGames/myCreatedGames
                      // OR if the participants list on the game itself contains them.
                      final isAlreadyJoined = currentUserId != null && (
                        joinedGameIds.contains(game.id) ||
                        game.isCreator(currentUserId) ||
                        game.isParticipant(currentUserId)
                      );
                        final isAlreadyCreator = createdGameIds.contains(game.id) ||
                          (currentUserId != null && game.isCreator(currentUserId));
                      
                      // Debug logging
                      if (currentUserId != null && game.isCreator(currentUserId)) {
                        debugPrint('[OnlineGames] Game ${game.title} (${game.id}): creatorId=${game.creatorId}, currentUserId=$currentUserId, isAlreadyCreator=$isAlreadyCreator, inCreatedList=${createdGameIds.contains(game.id)}');
                      }
                      
                      return GameCard(
                        game: game,
                        currentUserId: currentUserId,
                        isAlreadyJoined: isAlreadyJoined,
                        isAlreadyCreator: isAlreadyCreator,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameDetailPage(
                              gameId: game.id,
                              preloadedGame: game,
                            ),
                          ),
                        ),
                        onJoin: () => doAction(
                          () async {
                            final result = await ref.read(gameProvider.notifier).joinGame(game.id);
                            return result != null;
                          },
                          'Joined game!',
                          'Failed to join',
                        ),
                        onLeave: () => doAction(
                          () async {
                            final result = await ref.read(gameProvider.notifier).leaveGame(game.id);
                            if (result != null) ref.read(chatProvider.notifier).leaveRoom(game.id);
                            return result != null;
                          },
                          'Left game',
                          'Failed to leave',
                        ),
                        onCancel: () => doAction(
                          () async {
                            final result = await ref.read(gameProvider.notifier).cancelGame(game.id);
                            return result != null;
                          },
                          'Game cancelled',
                          'Failed to cancel',
                        ),
                        onDelete: isAlreadyCreator ? () => confirmDelete(game.id) : null,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Create Game',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xxl),
              decoration: const BoxDecoration(
                  color: AppColors.surfaceLight, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_rounded,
                  size: 56, color: AppColors.textTertiary),
            ),
            SizedBox(height: AppSpacing.xl),
            Text('No Online Games Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Be the first to create an online game\nand invite players to join!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, height: 1.5),
            ),
            SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Online Game',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.md + 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

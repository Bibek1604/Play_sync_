import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../widgets/create_game_sheet.dart';
import '../../domain/entities/game_entity.dart';
import 'game_detail_page.dart';

/// Filter options for offline games
enum OfflineFilter { all, open, myGames }

/// Offline Games — organized with filter tabs.
class OfflineGamesPage extends ConsumerStatefulWidget {
  const OfflineGamesPage({super.key});

  @override
  ConsumerState<OfflineGamesPage> createState() => _OfflineGamesPageState();
}

class _OfflineGamesPageState extends ConsumerState<OfflineGamesPage> {
  OfflineFilter _selectedFilter = OfflineFilter.all;

  @override
  void initState() {
    super.initState();
    // Load joined/created game lists so we can detect already-joined games
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateGameSheet(isOnlineMode: false),
    );
  }

  List<GameEntity> _getFilteredGames(List<GameEntity> allOfflineGames, String? userId) {
    switch (_selectedFilter) {
      case OfflineFilter.all:
        return allOfflineGames;
      case OfflineFilter.open:
        return allOfflineGames.where((g) => g.isOpen).toList();
      case OfflineFilter.myGames:
        if (userId == null) return [];
        return allOfflineGames.where((g) => 
          g.isCreator(userId) || g.isParticipant(userId)
        ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.userId;
    final allOfflineGames = state.games.where((g) => g.isOffline).toList();
    final filteredGames = _getFilteredGames(allOfflineGames, currentUserId);

    // Build a set of joined + created game IDs for quick lookup
    final joinedGameIds = <String>{
      ...state.myJoinedGames.map((g) => g.id),
      ...state.myCreatedGames.map((g) => g.id),
    };

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
              'Are you sure you want to delete this game? This cannot be undone.'),
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
        title: Text('Offline Games',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  count: allOfflineGames.length,
                  isSelected: _selectedFilter == OfflineFilter.all,
                  onTap: () => setState(() => _selectedFilter = OfflineFilter.all),
                ),
                SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'Open',
                  count: allOfflineGames.where((g) => g.isOpen).length,
                  isSelected: _selectedFilter == OfflineFilter.open,
                  onTap: () => setState(() => _selectedFilter = OfflineFilter.open),
                ),
                SizedBox(width: AppSpacing.sm),
                _FilterChip(
                  label: 'My Games',
                  count: currentUserId != null 
                    ? allOfflineGames.where((g) => g.isCreator(currentUserId) || g.isParticipant(currentUserId)).length 
                    : 0,
                  isSelected: _selectedFilter == OfflineFilter.myGames,
                  onTap: () => setState(() => _selectedFilter = OfflineFilter.myGames),
                ),
              ],
            ),
          ),
        ),
      ),
      body: state.isLoading && allOfflineGames.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary))
          : filteredGames.isEmpty
              ? _EmptyState(
                  filter: _selectedFilter,
                  onCreateTap: () => _showCreateSheet(context),
                  onShowAll: () => setState(() => _selectedFilter = OfflineFilter.all),
                )
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
                    itemCount: filteredGames.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) {
                      final game = filteredGames[i];
                      // A user is "joined" if they appear in myJoinedGames/myCreatedGames
                      // OR if the participants list on the game itself contains them.
                      final isAlreadyJoined = currentUserId != null && (
                        joinedGameIds.contains(game.id) ||
                        game.isCreator(currentUserId) ||
                        game.isParticipant(currentUserId)
                      );
                      return GameCard(
                        game: game,
                        currentUserId: currentUserId,
                        isAlreadyJoined: isAlreadyJoined,
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
                            return result != null;
                          },
                          'Left game',
                          'Failed to leave',
                        ),
                        onDelete: () => confirmDelete(game.id),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final OfflineFilter filter;
  final VoidCallback onCreateTap;
  final VoidCallback onShowAll;

  const _EmptyState({
    required this.filter,
    required this.onCreateTap,
    required this.onShowAll,
  });

  String get _title => switch (filter) {
    OfflineFilter.all => 'No Offline Games Yet',
    OfflineFilter.open => 'No Open Games',
    OfflineFilter.myGames => 'No Games You\'re Part Of',
  };

  String get _subtitle => switch (filter) {
    OfflineFilter.all => 'Organise a local match and meet\nplayers in your area!',
    OfflineFilter.open => 'All games are either full or ended.\nCreate a new one!',
    OfflineFilter.myGames => 'Join a game or create your own\nto see it here.',
  };

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
              child: Icon(
                filter == OfflineFilter.myGames 
                    ? Icons.person_outline_rounded 
                    : Icons.sports_rounded,
                size: 56, 
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(_title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            SizedBox(height: AppSpacing.sm),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary, height: 1.5),
            ),
            SizedBox(height: AppSpacing.xxl),
            if (filter != OfflineFilter.all) ...[
              OutlinedButton(
                onPressed: onShowAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: const Text('Show All Games',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              SizedBox(height: AppSpacing.md),
            ],
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Create Offline Game',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/presentation/providers/offline_game_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/create_game_dialog.dart';
import 'package:play_sync_new/features/game/presentation/widgets/offline_game_card.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:play_sync_new/app/routes/app_routes.dart';

/// Offline Games Page
///
/// Shows all available offline/local games with:
/// - Riverpod-powered data (offlineGamesProvider)
/// - Role-based buttons computed in provider
/// - Professional card layout
/// - Clean error / empty / loading states
class OfflineGamesPage extends ConsumerStatefulWidget {
  const OfflineGamesPage({super.key});

  @override
  ConsumerState<OfflineGamesPage> createState() => _OfflineGamesPageState();
}

class _OfflineGamesPageState extends ConsumerState<OfflineGamesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(offlineGamesProvider.notifier).loadGames(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gamesState = ref.watch(offlineGamesProvider);

    // Show error SnackBar (non-blocking) whenever a new error arrives.
    ref.listen<OfflineGamesState>(offlineGamesProvider, (prev, next) {
      if (next.hasError && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundPrimaryDark
          : AppColors.backgroundSecondaryLight,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(child: _buildBody(gamesState)),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return GlassCard(
      margin: AppSpacing.paddingMD,
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Offline Games', style: AppTypography.h2),
                Text(
                  'Find & join local games near you',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
          // ── Create Game button (top-right) ──────────────────────────
          Tooltip(
            message: 'Create a new offline game',
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const CreateGameDialog(),
              ),
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

  // ── Search ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by title, location, tag…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.slate200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.emerald500, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────

  Widget _buildBody(OfflineGamesState state) {
    if (state.isLoading && state.games.isEmpty) {
      return _buildLoadingList();
    }

    final filteredGames =
        ref.watch(filteredOfflineGamesProvider(_searchQuery));

    if (filteredGames.isEmpty) {
      return _buildEmpty(state.games.isEmpty
          ? 'No offline games available.\nCreate one to get started!'
          : 'No results for "$_searchQuery".');
    }

    return RefreshIndicator(
      color: AppColors.emerald500,
      onRefresh: () => ref.read(offlineGamesProvider.notifier).loadGames(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: filteredGames.length,
        itemBuilder: (_, i) => OfflineGameCard(
          game: filteredGames[i],
          onJoin: () => _handleJoin(filteredGames[i]),
          onChat: () => _navigateToChat(filteredGames[i].id),
          onDelete: () => _handleDelete(filteredGames[i]),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: 4,
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_searching_outlined,
                size: 72, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.slate500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _handleDelete(Game game) async {
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
        content: Text(
            'Delete "${game.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(offlineGamesProvider.notifier).deleteGame(game.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${game.title}" deleted.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      // Error already shown via listener above.
    }
  }

  Future<void> _handleJoin(Game game) async {
    try {
      await ref.read(offlineGamesProvider.notifier).joinGame(game.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${game.title}" successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        _navigateToChat(game.id);
      }
    } catch (_) {
      // Error already shown via listener above.
    }
  }

  void _navigateToChat(String gameId) {
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {'gameId': gameId},
    );
  }
}

// ── Skeleton card ──────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(44, 44, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmer(14, 160),
                    const SizedBox(height: 6),
                    _shimmer(10, 80),
                  ],
                ),
              ),
              _shimmer(22, 52, radius: 20),
            ],
          ),
          const SizedBox(height: 14),
          _shimmer(10, double.infinity),
          const SizedBox(height: 8),
          _shimmer(10, 200),
          const SizedBox(height: 14),
          _shimmer(5, double.infinity),
          const SizedBox(height: 14),
          _shimmer(44, double.infinity, radius: 12),
        ],
      ),
    );
  }

  Widget _shimmer(double h, double w, {double radius = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.slate200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

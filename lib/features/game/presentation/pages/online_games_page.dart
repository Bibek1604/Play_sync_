import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../widgets/create_game_sheet.dart';

/// Online games page — shows only games with [isOnline == true].
class OnlineGamesPage extends ConsumerWidget {
  const OnlineGamesPage({super.key});

  void _showCreateGameSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGameSheet(isOnlineMode: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final onlineGames = state.games.where((g) => g.isOnline).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Online Games',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () =>
                ref.read(gameProvider.notifier).fetchGames(refresh: true),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      backgroundColor: AppColors.background,
      body: state.isLoading && onlineGames.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : onlineGames.isEmpty
              ? _buildEmptyState(context, ref)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref
                      .read(gameProvider.notifier)
                      .fetchGames(refresh: true),
                  child: ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: onlineGames.length,
                    separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => GameCard(game: onlineGames[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGameSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        icon: const Icon(Icons.add, size: 22),
        label: const Text(
          'Create Online Game',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              'No Online Games Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Be the first to create an online game\nand invite players to join!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () => _showCreateGameSheet(context),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'Create Online Game',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md + 2,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

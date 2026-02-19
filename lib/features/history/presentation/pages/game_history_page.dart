import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/features/history/domain/entities/game_history.dart';
import 'package:play_sync_new/features/history/presentation/providers/history_notifier.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Game History Page
/// 
/// Displays user's past game sessions with stats
class GameHistoryPage extends ConsumerStatefulWidget {
  const GameHistoryPage({super.key});

  @override
  ConsumerState<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends ConsumerState<GameHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Load history and stats on page load
    Future.microtask(() {
      ref.read(historyNotifierProvider.notifier).refresh();
    });

    // Load more when reaching the bottom
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyState = ref.watch(historyNotifierProvider);

    return Scaffold(
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

              // Stats Card
              if (historyState.stats != null)
                _buildStatsCard(historyState.stats!, isDark),

              // History List
              Expanded(
                child: _buildHistoryList(historyState, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GlassCard(
      margin: AppSpacing.paddingMD,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.emerald500,
          ),
          AppSpacing.gapHorizontalMD,
          const Expanded(
            child: Text(
              'Game History',
              style: AppTypography.h2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppBorderRadius.chip,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 16, color: Colors.white),
                AppSpacing.gapHorizontalSM,
                Text(
                  'HISTORY',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(dynamic stats, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // First row: Total Games and Active Games
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: _StatItem(
                      icon: Icons.emoji_events,
                      label: 'Total Games',
                      value: stats.totalGames.toString(),
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapHorizontalMD,
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: _StatItem(
                      icon: Icons.trending_up,
                      label: 'Active',
                      value: (stats.totalGames - stats.completedGames).toString(),
                      color: AppColors.info,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMD,
          // Second row: Completed and Left Early
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: _StatItem(
                      icon: Icons.check_circle,
                      label: 'Completed',
                      value: stats.completedGames.toString(),
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapHorizontalMD,
              Expanded(
                child: GlassCard(
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: _StatItem(
                      icon: Icons.group,
                      label: 'Left Early',
                      value: '0',
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(HistoryState state, bool isDark) {
    if (state.isLoading && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            AppSpacing.gapVerticalMD,
            Text(
              state.error!,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVerticalLG,
            ElevatedButton(
              onPressed: () => ref.read(historyNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.history.isEmpty) {
      return EmptyState(
        icon: Icons.history,
        title: 'No game history yet',
        message: 'Your completed games will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.history.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.history.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _HistoryCard(
            history: state.history[index],
            isDark: isDark,
          );
        },
      ),
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        AppSpacing.gapVerticalSM,
        Text(
          value,
          style: AppTypography.h2.copyWith(color: color),
        ),
        AppSpacing.gapVerticalXS,
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}

/// History Card Widget
class _HistoryCard extends StatelessWidget {
  final GameHistory history;
  final bool isDark;

  const _HistoryCard({
    required this.history,
    required this.isDark,
  });

  Color _getStatusColor() {
    if (history.isCompleted) return AppColors.success;
    if (history.isCancelled) return AppColors.error;
    return AppColors.warning;
  }

  IconData _getStatusIcon() {
    if (history.isCompleted) return Icons.check_circle;
    if (history.isCancelled) return Icons.cancel;
    return Icons.play_circle;
  }

  String _getStatusText() {
    if (history.isCompleted) return 'Completed';
    if (history.isCancelled) return 'Cancelled';
    return 'In Progress';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    history.game.name,
                    style: AppTypography.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 16,
                      color: _getStatusColor(),
                    ),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      _getStatusText(),
                      style: AppTypography.caption.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,

            // Date and duration
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                AppSpacing.gapHorizontalSM,
                Text(
                  dateFormat.format(history.joinedAt),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                AppSpacing.gapHorizontalMD,
                Icon(
                  Icons.timer,
                  size: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                AppSpacing.gapHorizontalSM,
                Text(
                  history.formattedDuration,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMD,

            // Points earned
            if (history.pointsEarned > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppBorderRadius.radiusSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.white),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      '+${history.pointsEarned} points',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Left early indicator
            if (history.leftEarly)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: AppBorderRadius.radiusSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    AppSpacing.gapHorizontalSM,
                    Text(
                      'Left Early',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

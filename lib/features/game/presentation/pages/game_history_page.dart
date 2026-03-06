import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/game_notifier.dart';

/// Game History/Journey Page
/// Shows all games player has joined and participated in
class GameHistoryPage extends ConsumerStatefulWidget {
  const GameHistoryPage({super.key});

  @override
  ConsumerState<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends ConsumerState<GameHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Load all games on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // All games combined: created + joined
    final allGames = [...gameState.myCreatedGames, ...gameState.myJoinedGames];
    final sortedGames = allGames
        .where((game) => game.participants.isNotEmpty)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        title: Text(
          'Gaming Journey',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(gameProvider.notifier).fetchMyJoinedGames();
        },
        child: sortedGames.isEmpty
            ? _EmptyHistoryState()
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: sortedGames.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) {
                  final game = sortedGames[index];
                  return _GameHistoryCard(game: game, isDark: isDark);
                },
              ),
      ),
    );
  }
}

/// Individual game history card
class _GameHistoryCard extends StatelessWidget {
  final dynamic game;
  final bool isDark;

  const _GameHistoryCard({
    required this.game,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = game.isOnline;
    final participantCount = game.participants?.length ?? 0;
    final createdDate = game.createdAt ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(createdDate);
    final formattedTime = DateFormat('hh:mm a').format(createdDate);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title ?? 'Unnamed Game',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${game.creatorName.isNotEmpty ? game.creatorName : 'Unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.status.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Timeline info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Game details row
            Row(
              children: [
                Expanded(
                  child: _HistoryDetailItem(
                    icon: isOnline
                        ? Icons.public_rounded
                        : Icons.location_on_rounded,
                    label: isOnline ? 'Online' : 'Offline',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _HistoryDetailItem(
                    icon: Icons.people_rounded,
                    label: '$participantCount Players',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _HistoryDetailItem(
                    icon: Icons.gamepad_rounded,
                    label: game.category ?? 'Game',
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            if (game.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                game.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'View Details',
                    icon: Icons.info_outline_rounded,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/game-detail',
                        arguments: {'game': game},
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: isOnline ? 'Open Chat' : 'View Game',
                    icon: isOnline ? Icons.chat_rounded : Icons.location_on_rounded,
                    onPressed: isOnline
                        ? () {
                            Navigator.pushNamed(
                              context,
                              '/game-chat',
                              arguments: {'game': game},
                            );
                          }
                        : () {
                            Navigator.pushNamed(
                              context,
                              '/offline-detail',
                              arguments: {'game': game},
                            );
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last.toUpperCase();
    switch (statusStr) {
      case 'OPEN':
        return Colors.green;
      case 'FULL':
        return Colors.orange;
      case 'ENDED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

/// Detail item widget for history card
class _HistoryDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _HistoryDetailItem({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty state widget
class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Gaming History Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Join or create games to see your gaming journey here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

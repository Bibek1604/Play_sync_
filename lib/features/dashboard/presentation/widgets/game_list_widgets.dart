import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../../../features/game/domain/entities/game_entity.dart';
import '../../../../../../features/game/presentation/providers/game_notifier.dart';
import '../../../../../../features/game/presentation/pages/game_detail_page.dart';
import 'package:intl/intl.dart';

/// Offline Game List Widget
/// Displays only offline games from the state.
/// Does NOT fetch games - relies on parent to manage fetching.
/// 
/// This widget is responsible for:
/// - Displaying offline games only
/// - Showing game list UI
/// - Navigating to game details
/// - No API calls
class OfflineGameListWidget extends ConsumerWidget {
  final List<GameEntity> offlineGames;
  final bool isLoading;
  final String? currentUserId;
  final VoidCallback? onDeleteGame;

  const OfflineGameListWidget({
    super.key,
    required this.offlineGames,
    this.isLoading = false,
    this.currentUserId,
    this.onDeleteGame,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Label('Offline Games'),
            if (offlineGames.isNotEmpty)
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.offlineGames),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text(
                  'See All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Loading State ──────────────────────────────────────────────
        if (isLoading && offlineGames.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          )
        // ── Empty State ────────────────────────────────────────────────
        else if (offlineGames.isEmpty)
          _EmptySection(
            label: 'No offline games nearby.',
            onBrowse: () =>
                Navigator.pushNamed(context, AppRoutes.offlineGames),
          )
        // ── Game List ──────────────────────────────────────────────────
        else
          ...offlineGames.map(
            (game) => _GameTile(
              game: game,
              currentUserId: currentUserId,
              onDelete: onDeleteGame,
            ),
          ),
      ],
    );
  }
}

/// Online Game List Widget
/// Displays only online games from the state.
/// Does NOT fetch games - relies on parent to manage fetching.
/// 
/// This widget is responsible for:
/// - Displaying online games only
/// - Showing game list UI
/// - Navigating to game details
/// - No API calls
class OnlineGameListWidget extends ConsumerWidget {
  final List<GameEntity> onlineGames;
  final bool isLoading;
  final String? currentUserId;
  final VoidCallback? onDeleteGame;

  const OnlineGameListWidget({
    super.key,
    required this.onlineGames,
    this.isLoading = false,
    this.currentUserId,
    this.onDeleteGame,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Header ─────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Label('Online Games'),
            if (onlineGames.isNotEmpty)
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.onlineGames),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text(
                  'See All',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Loading State ──────────────────────────────────────────────
        if (isLoading && onlineGames.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          )
        // ── Empty State ────────────────────────────────────────────────
        else if (onlineGames.isEmpty)
          _EmptySection(
            label: 'No online games available.',
            onBrowse: () =>
                Navigator.pushNamed(context, AppRoutes.onlineGames),
          )
        // ── Game List ──────────────────────────────────────────────────
        else
          ...onlineGames.map(
            (game) => _GameTile(
              game: game,
              currentUserId: currentUserId,
              onDelete: onDeleteGame,
            ),
          ),
      ],
    );
  }
}

// ─── Shared Helper Widgets ───────────────────────────────────────────────────

/// Section Label
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    ),
  );
}

/// Empty State Widget
class _EmptySection extends StatelessWidget {
  final String label;
  final VoidCallback onBrowse;

  const _EmptySection({
    required this.label,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.sports_esports_outlined,
            size: 36,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onBrowse,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Explore Games'),
          ),
        ],
      ),
    );
  }
}

/// Game Tile - Displays individual game info
class _GameTile extends StatelessWidget {
  final GameEntity game;
  final String? currentUserId;
  final VoidCallback? onDelete;

  const _GameTile({
    required this.game,
    this.currentUserId,
    this.onDelete,
  });

  Color _statusColor() {
    switch (game.status) {
      case GameStatus.OPEN:
        return AppColors.success;
      case GameStatus.FULL:
        return AppColors.warning;
      case GameStatus.ENDED:
        return AppColors.textTertiary;
      case GameStatus.CANCELLED:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor();
    final isCreator = currentUserId != null && game.isCreator(currentUserId!);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameDetailPage(
            gameId: game.id,
            preloadedGame: game,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${game.sport} · ${game.currentPlayers}/${game.maxPlayers} players',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (game.startTime != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy · hh:mm a').format(game.startTime!),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isCreator && onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (game.category == 'ONLINE'
                            ? AppColors.info
                            : AppColors.success)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.category,
                    style: TextStyle(
                      color: game.category == 'ONLINE'
                          ? AppColors.info
                          : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    game.status.name,
                    style: TextStyle(
                      color: sc,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

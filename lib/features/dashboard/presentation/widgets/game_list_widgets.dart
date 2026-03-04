import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../app/routes/app_routes.dart';
import 'package:intl/intl.dart';
import '../../../../../../features/game/domain/entities/game_entity.dart';
import 'game_tile_widget.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Label('Offline Games'),
            if (offlineGames.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.offlineGames),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('See All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),

        if (isLoading && offlineGames.isEmpty)
          const _LoadingTile()
        else if (offlineGames.isEmpty)
          _EmptySection(
            label: 'No offline games nearby.',
            onBrowse: () => Navigator.pushNamed(context, AppRoutes.offlineGames),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: offlineGames.length,
            itemBuilder: (context, index) => GameTileWidget(
              game: offlineGames[index],
              currentUserId: currentUserId,
              onDelete: onDeleteGame,
            ),
          ),
      ],
    );
  }
}

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Label('Online Games'),
            if (onlineGames.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('See All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),

        if (isLoading && onlineGames.isEmpty)
          const _LoadingTile()
        else if (onlineGames.isEmpty)
          _EmptySection(
            label: 'No online games available.',
            onBrowse: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: onlineGames.length,
            itemBuilder: (context, index) => GameTileWidget(
              game: onlineGames[index],
              currentUserId: currentUserId,
              onDelete: onDeleteGame,
            ),
          ),
      ],
    );
  }
}

// ── Shared Helper Widgets ───────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      );
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.space24),
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
        ),
      );
}

class _EmptySection extends StatelessWidget {
  final String label;
  final VoidCallback onBrowse;

  const _EmptySection({required this.label, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_esports_outlined,
              size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// End of helper widgets

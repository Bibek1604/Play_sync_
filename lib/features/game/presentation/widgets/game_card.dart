import 'package:flutter/material.dart';
import '../../domain/entities/game_entity.dart';

/// Small card displaying a single game in the list.
class GameCard extends StatelessWidget {
  final GameEntity game;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const GameCard({super.key, required this.game, this.onTap, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryIcon(category: game.category),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(game.title,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  _StatusChip(status: game.status),
                ],
              ),
              if (game.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(game.description,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(game.isOnline ? Icons.wifi : Icons.location_on_outlined,
                      size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game.isOnline ? 'Online' : (game.location ?? 'Location TBD'),
                      style: tt.labelSmall?.copyWith(color: cs.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.group_outlined, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text('${game.currentPlayers}/${game.maxPlayers}',
                      style: tt.labelSmall?.copyWith(
                          color: game.isFull ? cs.error : cs.outline)),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_outlined, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(_formatDate(game.scheduledAt),
                      style: tt.labelSmall?.copyWith(color: cs.outline)),
                ],
              ),
              if (!game.isFull &&
                  game.status == GameStatus.upcoming &&
                  onJoin != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onJoin,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: Text('Join · ${game.spotsLeft} spots left',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now);
    if (diff.inDays == 0) {
      final h = diff.inHours;
      return h <= 0 ? 'Now' : 'In ${h}h';
    }
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return '${-diff.inDays}d ago';
    return 'In ${diff.inDays}d';
  }
}

class _CategoryIcon extends StatelessWidget {
  final GameCategory category;
  const _CategoryIcon({required this.category});

  IconData get icon => switch (category) {
        GameCategory.football => Icons.sports_soccer,
        GameCategory.basketball => Icons.sports_basketball,
        GameCategory.cricket => Icons.sports_cricket,
        GameCategory.tennis => Icons.sports_tennis,
        GameCategory.badminton => Icons.sports,
        GameCategory.chess => Icons.extension,
        GameCategory.other => Icons.sports_esports,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GameStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GameStatus.upcoming => ('Soon', Colors.blue),
      GameStatus.live => ('LIVE', Colors.red),
      GameStatus.completed => ('Done', Colors.grey),
      GameStatus.cancelled => ('Off', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.4)),
    );
  }
}

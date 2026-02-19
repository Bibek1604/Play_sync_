import 'package:flutter/material.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_stats.dart';

/// A compact card showing a user's key stats (games, wins, points, streak).
class ProfileStatsCard extends StatelessWidget {
  final ProfileStats stats;

  const ProfileStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(
              label: 'Played',
              value: '${stats.totalGamesPlayed}',
              icon: Icons.sports_esports_rounded,
            ),
            _Divider(),
            _Stat(
              label: 'Won',
              value: '${stats.gamesWon}',
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFF38A169),
            ),
            _Divider(),
            _Stat(
              label: 'Points',
              value: '${stats.totalPoints}',
              icon: Icons.star_rounded,
              color: const Color(0xFFD69E2E),
            ),
            _Divider(),
            _Stat(
              label: 'Streak',
              value: '${stats.currentStreak}🔥',
              icon: Icons.local_fire_department_rounded,
              color: const Color(0xFFE53E3E),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        width: 1,
        color: Colors.grey.shade200,
      );
}

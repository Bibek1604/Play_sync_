import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/routes/app_routes.dart';

/// Quick Action Widget - ONLY displays navigation buttons.
/// Does NOT fetch or display any game data.
/// Does NOT call any API endpoints.
/// 
/// This widget is responsible for:
/// - Displaying quick action buttons (Offline, Online, History, Rankings)
/// - Handling navigation only
/// - No state management related to games
class QuickActionWidget extends StatelessWidget {
  const QuickActionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ──────────────────────────────────────────────
        const _Label('Quick Actions'),
        const SizedBox(height: 14),

        // ── Action Buttons Row ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.wifi_off_rounded,
                title: 'Offline',
                subtitle: 'Local matches',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.offlineGames,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.wifi_rounded,
                title: 'Online',
                subtitle: 'Play remotely',
                color: AppColors.info,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.onlineGames,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.history_rounded,
                title: 'History',
                subtitle: 'Past games',
                color: AppColors.warning,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.gameHistory,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.leaderboard_rounded,
                title: 'Rankings',
                subtitle: 'Leaderboard',
                color: AppColors.success,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.rankings,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Section Label for Quick Actions
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

/// Action Card - Navigation button
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

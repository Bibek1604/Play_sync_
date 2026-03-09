import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_theme.dart';
import '../../../../../core/constants/app_spacing.dart';

/// Horizontal bar chart showing XP distribution across top-N leaderboard entries.
/// Built with CustomPainter — no external chart library.
class XpBarChart extends StatefulWidget {
  final List<LeaderboardEntry> entries;
  final int maxEntries;

  const XpBarChart({
    super.key,
    required this.entries,
    this.maxEntries = 10,
  });

  @override
  State<XpBarChart> createState() => _XpBarChartState();
}

class _XpBarChartState extends State<XpBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.entries.take(widget.maxEntries).toList();
    if (visible.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('No data',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ),
      );
    }

    final maxXp = visible.map((e) => e.xp).reduce(math.max);
    const barHeight = 20.0;
    const barGap = 10.0;
    const labelWidth = 28.0; // rank number
    const nameWidth = 90.0;
    const xpLabelWidth = 48.0;
    final chartHeight = visible.length * (barHeight + barGap) + barGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => CustomPaint(
            size: Size(double.infinity, chartHeight),
            painter: _BarPainter(
              entries: visible,
              maxXp: maxXp,
              progress: _anim.value,
              barHeight: barHeight,
              barGap: barGap,
              labelWidth: labelWidth,
              nameWidth: nameWidth,
              xpLabelWidth: xpLabelWidth,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        // Legend
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            const Text('Others',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 12),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: AppColors.rankGold, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            const Text('Top 3',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<LeaderboardEntry> entries;
  final int maxXp;
  final double progress;
  final double barHeight;
  final double barGap;
  final double labelWidth;
  final double nameWidth;
  final double xpLabelWidth;

  _BarPainter({
    required this.entries,
    required this.maxXp,
    required this.progress,
    required this.barHeight,
    required this.barGap,
    required this.labelWidth,
    required this.nameWidth,
    required this.xpLabelWidth,
  });

  Color _barColor(int rank) {
    if (rank == 1) return AppColors.rankGold;
    if (rank == 2) return AppColors.rankSilver;
    if (rank == 3) return AppColors.rankBronze;
    return AppColors.primary;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final availableWidth =
        size.width - labelWidth - nameWidth - xpLabelWidth - 16;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final y = barGap + i * (barHeight + barGap);
_drawText(
        canvas,
        '#${entry.rank}',
        Offset(0, y + barHeight / 2 - 6),
        const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary),
        maxWidth: labelWidth,
      );
final nameX = labelWidth + 4;
      _drawText(
        canvas,
        entry.fullName.length > 12
            ? '${entry.fullName.substring(0, 10)}…'
            : entry.fullName,
        Offset(nameX, y + barHeight / 2 - 6),
        TextStyle(
          fontSize: 11,
          fontWeight: entry.isCurrentUser ? FontWeight.w700 : FontWeight.w500,
          color: entry.isCurrentUser
              ? AppColors.primary
              : AppColors.textPrimary,
        ),
        maxWidth: nameWidth,
      );
final barX = labelWidth + nameWidth + 8;
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, y, availableWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(
          bgRect, Paint()..color = AppColors.surfaceLight);
final fillWidth = maxXp > 0
          ? (entry.xp / maxXp) * availableWidth * progress
          : 0.0;
      if (fillWidth > 4) {
        final fillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, y, fillWidth, barHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(
            fillRect, Paint()..color = _barColor(entry.rank));
      }
final xpX = barX + availableWidth + 6;
      _drawText(
        canvas,
        '${entry.xp}',
        Offset(xpX, y + barHeight / 2 - 6),
        const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary),
        maxWidth: xpLabelWidth,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.entries != entries;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A donut / ring chart for Win / Loss / Draw breakdown.
/// Drawn with CustomPainter — no external dependency.
class StatsRingChart extends StatefulWidget {
  final int wins;
  final int losses;
  final int draws;

  const StatsRingChart({
    super.key,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  @override
  State<StatsRingChart> createState() => _StatsRingChartState();
}

class _StatsRingChartState extends State<StatsRingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _sweep = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.wins + widget.losses + widget.draws;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _sweep,
          builder: (_, _) => CustomPaint(
            size: const Size(140, 140),
            painter: _RingPainter(
              wins: widget.wins,
              losses: widget.losses,
              draws: widget.draws,
              total: total,
              progress: _sweep.value,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.success, label: 'Wins', value: widget.wins),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.error, label: 'Losses', value: widget.losses),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.info, label: 'Draws', value: widget.draws),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final int wins, losses, draws, total;
  final double progress;

  _RingPainter({
    required this.wins,
    required this.losses,
    required this.draws,
    required this.total,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 12;
    const strokeWidth = 22.0;
    const gapAngle = 0.04; // radians between segments

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const startAngle = -math.pi / 2;

    // Background ring
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.surfaceLight;
    canvas.drawCircle(Offset(cx, cy), radius, bgPaint);

    if (total == 0) return;

    final segments = [
      (wins / total, AppColors.success),
      (losses / total, AppColors.error),
      (draws / total, AppColors.info),
    ];

    double currentAngle = startAngle;
    final sweepTotal = progress * (2 * math.pi);

    for (final seg in segments) {
      final fraction = seg.$1;
      final color = seg.$2;
      if (fraction == 0) continue;

      final segSweep = (sweepTotal * fraction).clamp(0.0, 2 * math.pi);
      final actualSweep =
          (segSweep - gapAngle).clamp(0.0, 2 * math.pi).toDouble();

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color;

      canvas.drawArc(rect, currentAngle, actualSweep, false, paint);
      currentAngle += segSweep;
    }

    // Centre label
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: total == 0 ? '--' : total.toString(),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const TextSpan(
            text: '\ngames',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.total != total;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _LegendDot(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
            Text(value.toString(),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

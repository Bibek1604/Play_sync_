import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_theme.dart';

/// Compact summary card showing history stats counts across statuses.
class HistoryStatsCard extends StatelessWidget {
  final int total;
  final int ended;
  final int cancelled;
  final int active;
  final bool isCompact;

  const HistoryStatsCard({
    super.key,
    required this.total,
    required this.ended,
    required this.cancelled,
    required this.active,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StatTile(
                icon: Icons.sports_score_rounded,
                label: 'Total',
                value: total,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.sm),
              _StatTile(
                icon: Icons.check_circle_rounded,
                label: 'Ended',
                value: ended,
                color: AppColors.success,
              ),
              SizedBox(width: AppSpacing.sm),
              _StatTile(
                icon: Icons.cancel_rounded,
                label: 'Cancelled',
                value: cancelled,
                color: AppColors.error,
              ),
              SizedBox(width: AppSpacing.sm),
              _StatTile(
                icon: Icons.play_circle_rounded,
                label: 'Active',
                value: active,
                color: AppColors.warning,
              ),
            ],
          ),
          if (total > 0) ...[
            SizedBox(height: AppSpacing.md),
            _StackedBar(
              ended: ended,
              cancelled: cancelled,
              active: active,
              total: total,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stacked proportional bar ─────────────────────────────────────────────────
class _StackedBar extends StatefulWidget {
  final int ended, cancelled, active, total;
  const _StackedBar({
    required this.ended,
    required this.cancelled,
    required this.active,
    required this.total,
  });

  @override
  State<_StackedBar> createState() => _StackedBarState();
}

class _StackedBarState extends State<_StackedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
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
    final endedPct = widget.total > 0 ? widget.ended / widget.total : 0.0;
    final cancelledPct =
        widget.total > 0 ? widget.cancelled / widget.total : 0.0;
    final activePct = widget.total > 0 ? widget.active / widget.total : 0.0;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.circle),
        child: SizedBox(
          height: 8,
          child: Row(
            children: [
              Flexible(
                flex: (endedPct * 1000 * _anim.value).toInt().clamp(1, 1000),
                child: Container(color: AppColors.success),
              ),
              Flexible(
                flex:
                    (cancelledPct * 1000 * _anim.value).toInt().clamp(1, 1000),
                child: Container(color: AppColors.error),
              ),
              Flexible(
                flex: (activePct * 1000 * _anim.value).toInt().clamp(1, 1000),
                child: Container(color: AppColors.warning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Single stat tile ─────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

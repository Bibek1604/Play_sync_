import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/scorecard_notifier.dart';
import '../widgets/xp_bar.dart';
import '../widgets/stats_ring_chart.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/back_button_widget.dart';

class ScorecardPage extends ConsumerWidget {
  const ScorecardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorecardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BackButtonWidget(label: 'Back'),
        ),
        leadingWidth: 100,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        title: Text('My Scorecard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: () => ref.read(scorecardProvider.notifier).fetch(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary))
          : state.error != null && state.scorecard == null
              ? _ErrorView(
                  error: state.error!,
                  onRetry: () => ref.read(scorecardProvider.notifier).fetch(),
                )
              : state.scorecard == null
                  ? const Center(child: Text('No scorecard data'))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () =>
                          ref.read(scorecardProvider.notifier).fetch(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: _ScorecardBody(sc: state.scorecard!),
                      ),
                    ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
class _ScorecardBody extends StatelessWidget {
  final dynamic sc;
  const _ScorecardBody({required this.sc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Rank banner ──
        _RankBanner(rank: sc.rank),
        SizedBox(height: AppSpacing.lg),

        // ── XP Progress ──
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('XP & Level'),
              SizedBox(height: AppSpacing.md),
              XpProgressBar(
                level: sc.level,
                progress: sc.xpProgress,
                label: sc.xpProgressLabel,
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // ── Stats row ──
        Row(
          children: [
            Expanded(child: _StatChip(icon: Icons.emoji_events_rounded, label: 'Wins', value: sc.wins.toString(), color: AppColors.success)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatChip(icon: Icons.close_rounded, label: 'Losses', value: sc.losses.toString(), color: AppColors.error)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatChip(icon: Icons.sports_score_rounded, label: 'Games', value: sc.totalGames.toString(), color: AppColors.info)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatChip(icon: Icons.percent_rounded, label: 'Win Rate', value: sc.winRateLabel, color: AppColors.primary)),
          ],
        ),
        SizedBox(height: AppSpacing.md),

        // ── Ring chart ──
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Win / Loss Breakdown'),
              SizedBox(height: AppSpacing.md),
              Center(
                child: StatsRingChart(
                  wins: sc.wins,
                  losses: sc.losses,
                  draws: sc.draws,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),

        // ── Win rate bar ──
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Win Rate'),
              SizedBox(height: AppSpacing.md),
              _WinRateBar(winRate: sc.winRate, label: sc.winRateLabel),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ─── Rank Banner ──────────────────────────────────────────────────────────────
class _RankBanner extends StatelessWidget {
  final int rank;
  const _RankBanner({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.leaderboard_rounded, color: Colors.white, size: 40),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Global Rank',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13)),
              Text(
                rank > 0 ? '#$rank' : 'Unranked',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Win Rate Bar ─────────────────────────────────────────────────────────────
class _WinRateBar extends StatefulWidget {
  final double winRate;
  final String label;
  const _WinRateBar({required this.winRate, required this.label});

  @override
  State<_WinRateBar> createState() => _WinRateBarState();
}

class _WinRateBarState extends State<_WinRateBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = Tween<double>(begin: 0, end: widget.winRate)
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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Win Rate',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circle),
            child: LinearProgressIndicator(
              value: _anim.value,
              minHeight: 14,
              backgroundColor: AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

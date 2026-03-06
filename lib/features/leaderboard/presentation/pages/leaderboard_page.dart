import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_row.dart';
import '../widgets/leaderboard_podium.dart';
import '../../domain/value_objects/leaderboard_filter.dart';

class LeaderboardPage extends ConsumerWidget {
  static const routeName = '/leaderboard';
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);
    final canPop   = Navigator.of(context).canPop();
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFBAE6FD), Colors.white], // Sky blue matching bottom bar
            stops: const [0.0, 0.3],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              leading: canPop ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ) : null,
              title: const Text(
                'Champions',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                    onPressed: () => _showFilterSheet(context, ref, state.filter),
                  ),
                ),
              ],
            ),
          ],
          body: _buildBody(context, state, notifier),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LeaderboardState state,
      LeaderboardNotifier notifier) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
      );
    }

    if (state.error != null && state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: notifier.load,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final top3 = state.entries.take(3).toList();
    final rest = state.entries.skip(3).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      strokeWidth: 3,
      onRefresh: notifier.load,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header Section ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hall of Fame'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTertiary.withValues(alpha: 0.6),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _FilterPill(
                        label: state.filter.scope.name.toUpperCase(),
                        icon: Icons.public_rounded,
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(
                        label: state.filter.period.name.toUpperCase(),
                        icon: Icons.calendar_today_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Podium ────────────────────────────────────────────────
          if (top3.length == 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: LeaderboardPodium(
                  firstUsername:  top3[0].fullName,
                  secondUsername: top3[1].fullName,
                  thirdUsername:  top3[2].fullName,
                  firstAvatarUrl:  top3[0].avatar,
                  secondAvatarUrl: top3[1].avatar,
                  thirdAvatarUrl:  top3[2].avatar,
                  firstPoints:  top3[0].xp,
                  secondPoints: top3[1].xp,
                  thirdPoints:  top3[2].xp,
                ),
              ),
            ),

          // ── Rest of the list ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == rest.length) {
                    if (state.isLoading) {
                      return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: AppColors.primary)));
                    }
                    if (state.hasMore) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: OutlinedButton(
                          onPressed: notifier.loadMore,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Load more'),
                        ),
                      );
                    }
                    return const SizedBox(height: 100);
                  }
                  return LeaderboardRow(entry: rest[i]);
                },
                childCount: rest.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, WidgetRef ref, LeaderboardFilter current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LeaderboardFilterSheet(
        current: current,
        onApply: (f) => ref.read(leaderboardProvider.notifier).changeFilter(f),
      ),
    );
  }
}

// ── Filter Pill ────────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FilterPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Filter Sheet ───────────────────────────────────────────────────────────────

class _LeaderboardFilterSheet extends StatefulWidget {
  final LeaderboardFilter current;
  final void Function(LeaderboardFilter) onApply;
  const _LeaderboardFilterSheet(
      {required this.current, required this.onApply});

  @override
  State<_LeaderboardFilterSheet> createState() =>
      _LeaderboardFilterSheetState();
}

class _LeaderboardFilterSheetState extends State<_LeaderboardFilterSheet> {
  late LeaderboardPeriod _period;
  late LeaderboardScope _scope;

  @override
  void initState() {
    super.initState();
    _period = widget.current.period;
    _scope  = widget.current.scope;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter Leaderboard',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),

          // Period
          const Text('Period',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: LeaderboardPeriod.values
                .map((p) => ChoiceChip(
                      label: Text(p.name),
                      selected: _period == p,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                          color: _period == p
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      side: BorderSide(
                          color: _period == p
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border),
                      backgroundColor: AppColors.surface,
                      onSelected: (_) => setState(() => _period = p),
                    ))
                .toList(),
          ),

          const SizedBox(height: 16),

          // Scope
          const Text('Scope',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: LeaderboardScope.values
                .map((s) => ChoiceChip(
                      label: Text(s.name),
                      selected: _scope == s,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                          color: _scope == s
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      side: BorderSide(
                          color: _scope == s
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border),
                      backgroundColor: AppColors.surface,
                      onSelected: (_) => setState(() => _scope = s),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(widget.current
                    .copyWith(period: _period, scope: _scope, offset: 0));
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply Filters',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

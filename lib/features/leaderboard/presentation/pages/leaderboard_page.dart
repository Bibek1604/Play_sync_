import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_row.dart';
import '../widgets/leaderboard_podium.dart';
import '../../domain/value_objects/leaderboard_filter.dart';

class LeaderboardPage extends ConsumerWidget {
  static const routeName = '/leaderboard';

  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, ref, state.filter),
          ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, LeaderboardState state, LeaderboardNotifier notifier) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: notifier.load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final top3 = state.entries.take(3).toList();
    final rest = state.entries.skip(3).toList();

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: CustomScrollView(
        slivers: [
          if (top3.length == 3)
            SliverToBoxAdapter(
              child: LeaderboardPodium(
                firstUsername: top3[0].username,
                secondUsername: top3[1].username,
                thirdUsername: top3[2].username,
                firstAvatarUrl: top3[0].profileImageUrl,
                secondAvatarUrl: top3[1].profileImageUrl,
                thirdAvatarUrl: top3[2].profileImageUrl,
                firstPoints: top3[0].totalPoints,
                secondPoints: top3[1].totalPoints,
                thirdPoints: top3[2].totalPoints,
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (i == rest.length) {
                  if (state.isLoading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                  if (state.hasMore) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton(onPressed: notifier.loadMore, child: const Text('Load more')),
                    );
                  }
                  return const SizedBox(height: 32);
                }
                return LeaderboardRow(entry: rest[i]);
              },
              childCount: rest.length + 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, LeaderboardFilter current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _LeaderboardFilterSheet(current: current, onApply: (f) => ref.read(leaderboardProvider.notifier).changeFilter(f)),
    );
  }
}

class _LeaderboardFilterSheet extends StatefulWidget {
  final LeaderboardFilter current;
  final void Function(LeaderboardFilter) onApply;

  const _LeaderboardFilterSheet({required this.current, required this.onApply});

  @override
  State<_LeaderboardFilterSheet> createState() => _LeaderboardFilterSheetState();
}

class _LeaderboardFilterSheetState extends State<_LeaderboardFilterSheet> {
  late LeaderboardPeriod _period;
  late LeaderboardScope _scope;

  @override
  void initState() {
    super.initState();
    _period = widget.current.period;
    _scope = widget.current.scope;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Leaderboard', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Period', style: Theme.of(context).textTheme.labelMedium),
          Wrap(
            spacing: 8,
            children: LeaderboardPeriod.values.map((p) => ChoiceChip(
              label: Text(p.name),
              selected: _period == p,
              onSelected: (_) => setState(() => _period = p),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Text('Scope', style: Theme.of(context).textTheme.labelMedium),
          Wrap(
            spacing: 8,
            children: LeaderboardScope.values.map((s) => ChoiceChip(
              label: Text(s.name),
              selected: _scope == s,
              onSelected: (_) => setState(() => _scope = s),
            )).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(widget.current.copyWith(period: _period, scope: _scope, offset: 0));
              },
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

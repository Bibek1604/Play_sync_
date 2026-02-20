import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/history_notifier.dart';
import '../../domain/entities/game_history.dart';

/// Displays the user's personal game history with stats summary.
class GameHistoryPage extends ConsumerWidget {
  const GameHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(historyProvider.notifier).fetchHistory(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(historyProvider.notifier).fetchHistory(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Stats Row ─────────────────────────────────────────────
                  _StatsRow(state: state),
                  const SizedBox(height: 20),

                  // ── History List ─────────────────────────────────────────
                  if (state.error != null)
                    Center(
                      child: Text(state.error!,
                          style:
                              TextStyle(color: cs.error)),
                    )
                  else if (state.history.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No game history yet'),
                          ],
                        ),
                      ),
                    )
                  else
                    ...state.history.map((h) => _HistoryCard(history: h)),
                ],
              ),
            ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});
  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(value: '${state.totalGames}', label: 'Played'),
        const SizedBox(width: 8),
        _StatBox(
            value: '${state.wins}',
            label: 'Wins',
            color: Colors.green),
        const SizedBox(width: 8),
        _StatBox(
            value: '${state.losses}',
            label: 'Losses',
            color: Colors.red),
        const SizedBox(width: 8),
        _StatBox(
            value: '${state.draws}',
            label: 'Draws',
            color: Colors.orange),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color ?? cs.onSurface)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});
  final GameHistory history;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  Color _resultColor(BuildContext ctx, String result) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (result) {
      'win' => Colors.green,
      'loss' => cs.error,
      'draw' => Colors.orange,
      _ => cs.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Result icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _resultColor(context, history.result).withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(history.resultIcon,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),

            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(history.gameTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${history.category.toUpperCase()} • ${_dateFmt.format(history.date)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),

            // Result chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    _resultColor(context, history.result).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                history.result.toUpperCase(),
                style: TextStyle(
                  color: _resultColor(context, history.result),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/tournament_entity.dart';
import '../providers/tournament_notifier.dart';

/// Browse & search tournaments.
class TournamentListPage extends ConsumerStatefulWidget {
  const TournamentListPage({super.key});

  @override
  ConsumerState<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends ConsumerState<TournamentListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  static const _statuses = ['open', 'ongoing', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(tournamentProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Tournament',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.tournamentCreate),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'My Tournaments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Browse Tab ──────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterChips(state, isDark),
              Expanded(
                child: _buildTournamentList(
                  tournaments: state.tournaments,
                  isLoading: state.isLoading,
                  isLoadingMore: state.isLoadingMore,
                  error: state.error,
                  onRefresh: () =>
                      ref.read(tournamentProvider.notifier).fetchTournaments(refresh: true),
                ),
              ),
            ],
          ),
          // ── My Tournaments Tab ──────────────────────────────────────────
          _buildTournamentList(
            tournaments: state.myTournaments,
            isLoading: state.isLoading,
            error: state.error,
            onRefresh: () =>
                ref.read(tournamentProvider.notifier).fetchMyTournaments(),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ────────────────────────────────────────────────────────

  Widget _buildFilterChips(TournamentState state, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: state.statusFilter == null,
            onSelected: (_) =>
                ref.read(tournamentProvider.notifier).clearFilters(),
          ),
          const SizedBox(width: 8),
          ..._statuses.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s[0].toUpperCase() + s.substring(1)),
                selected: state.statusFilter == s,
                onSelected: (_) =>
                    ref.read(tournamentProvider.notifier).setStatusFilter(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tournament list ─────────────────────────────────────────────────────

  Widget _buildTournamentList({
    required List<TournamentEntity> tournaments,
    required bool isLoading,
    bool isLoadingMore = false,
    String? error,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading && tournaments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No tournaments found',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: tournaments.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tournaments.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _TournamentCard(tournament: tournaments[index]);
        },
      ),
    );
  }
}

// ── Tournament Card ───────────────────────────────────────────────────────

class _TournamentCard extends StatelessWidget {
  final TournamentEntity tournament;
  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.tournamentDetail,
          arguments: {'tournamentId': tournament.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(status: tournament.status),
                ],
              ),
              if (tournament.description != null &&
                  tournament.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  tournament.description!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              // Info row
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.people,
                    label:
                        '${tournament.currentPlayers}/${tournament.maxPlayers}',
                  ),
                  const SizedBox(width: 12),
                  if (tournament.entryFee > 0)
                    _InfoChip(
                      icon: Icons.monetization_on,
                      label: 'Rs. ${tournament.entryFee}',
                    ),
                  const Spacer(),
                  if (tournament.startDate != null)
                    Text(
                      df.format(tournament.startDate!),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TournamentStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      TournamentStatus.open => (Colors.green.shade100, Colors.green.shade800),
      TournamentStatus.ongoing => (Colors.blue.shade100, Colors.blue.shade800),
      TournamentStatus.completed =>
        (Colors.grey.shade200, Colors.grey.shade700),
      TournamentStatus.cancelled => (Colors.red.shade100, Colors.red.shade800),
      TournamentStatus.closed =>
        (Colors.orange.shade100, Colors.orange.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';

/// Main games listing page with filter tabs and category chips.
class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _filters = [
    GameFilter.all,
    GameFilter.upcoming,
    GameFilter.live,
    GameFilter.completed,
  ];

  static const _tabLabels = ['All', 'Upcoming', 'Live', 'Done'];
  static const _categories = [
    null,
    GameCategory.football,
    GameCategory.basketball,
    GameCategory.cricket,
    GameCategory.chess,
    GameCategory.tennis,
    GameCategory.badminton,
    GameCategory.other,
  ];
  static const _categoryLabels = [
    'All',
    '⚽ Football',
    '🏀 Basketball',
    '🏏 Cricket',
    '♟️ Chess',
    '🎾 Tennis',
    '🏸 Badminton',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(gameProvider.notifier).setFilter(_filters[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          isScrollable: false,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Host a game',
            onPressed: () => _showCreateGameSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final selected = state.categoryFilter == _categories[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_categoryLabels[i]),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(gameProvider.notifier).setCategoryFilter(_categories[i]),
                  ),
                );
              },
            ),
          ),
          // Game list
          Expanded(
            child: state.isLoading && state.games.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.filteredGames.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_esports,
                                size: 64,
                                color: cs.outline.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('No games found',
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => ref
                                  .read(gameProvider.notifier)
                                  .fetchGames(refresh: true),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(gameProvider.notifier).fetchGames(refresh: true),
                        child: ListView.builder(
                          itemCount: state.filteredGames.length +
                              (state.hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == state.filteredGames.length) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.read(gameProvider.notifier).fetchGames();
                              });
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }
                            final game = state.filteredGames[i];
                            return GameCard(
                              game: game,
                              onTap: () => _openGameDetail(context, game),
                              onJoin: () =>
                                  ref.read(gameProvider.notifier).joinGame(game.id),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openGameDetail(BuildContext context, GameEntity game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GameDetailSheet(game: game),
    );
  }

  void _showCreateGameSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateGameSheet(),
    );
  }
}

// ─── Game detail sheet ────────────────────────────────────────────────────────

class _GameDetailSheet extends ConsumerWidget {
  final GameEntity game;
  const _GameDetailSheet({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(game.title, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(game.description, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.category_outlined, label: game.category.name.toUpperCase()),
          _DetailRow(
            icon: game.isOnline ? Icons.wifi : Icons.location_on_outlined,
            label: game.isOnline ? 'Online' : (game.location ?? 'TBD'),
          ),
          _DetailRow(icon: Icons.group_outlined, label: '${game.currentPlayers} / ${game.maxPlayers} players'),
          _DetailRow(icon: Icons.calendar_today_outlined, label: game.scheduledAt.toString().substring(0, 16)),
          if (game.prizePool > 0)
            _DetailRow(icon: Icons.emoji_events_outlined, label: 'Prize pool: ₹${game.prizePool}'),
          const SizedBox(height: 20),
          if (!game.isFull && game.status == GameStatus.upcoming)
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Join Game'),
              onPressed: () {
                ref.read(gameProvider.notifier).joinGame(game.id);
                Navigator.pop(context);
              },
            ),
          if (game.status == GameStatus.live)
            FilledButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Game is LIVE'),
              onPressed: null,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ─── Create game sheet ────────────────────────────────────────────────────────

class _CreateGameSheet extends ConsumerStatefulWidget {
  const _CreateGameSheet();

  @override
  ConsumerState<_CreateGameSheet> createState() => _CreateGameSheetState();
}

class _CreateGameSheetState extends ConsumerState<_CreateGameSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  GameCategory _category = GameCategory.football;
  bool _isOnline = false;
  int _maxPlayers = 10;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Host a Game',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Game title', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GameCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: GameCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '$_maxPlayers',
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Max players', border: OutlineInputBorder()),
                    onChanged: (v) => _maxPlayers = int.tryParse(v) ?? 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Online'),
                    value: _isOnline,
                    onChanged: (v) => setState(() => _isOnline = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (!_isOnline) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Game created!')));
                  }
                },
                child: const Text('Create Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

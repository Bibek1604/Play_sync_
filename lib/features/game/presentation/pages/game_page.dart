import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../widgets/create_game_sheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';
import '../../../profile/presentation/viewmodel/profile_notifier.dart';

const _sports = [
  'All', 'Football', 'Basketball', 'Cricket', 'Chess', 'Tennis', 'Badminton', 'Other'
];
const _sportIcons = <String, IconData>{
  'Football':   Icons.sports_soccer,
  'Basketball': Icons.sports_basketball,
  'Cricket':    Icons.sports_cricket,
  'Chess':      Icons.casino_outlined,
  'Tennis':     Icons.sports_tennis,
  'Badminton':  Icons.sports_tennis,
  'Other':      Icons.sports,
  'All':        Icons.apps,
};

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});
  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage>
    with SingleTickerProviderStateMixin {
  late final TabController _statusTab;
  String _selectedSport = 'All';
  bool _showJoinedOnly = true;

  static const _filters = [
    GameFilter.all,
    GameFilter.OPEN,
    GameFilter.FULL,
    GameFilter.ENDED,
    GameFilter.CANCELLED,
  ];
  static const _tabLabels = [
    ('All', Icons.grid_view_rounded),
    ('Open', Icons.lock_open_rounded),
    ('Full', Icons.group_rounded),
    ('Ended', Icons.check_circle_outline),
    ('Cancelled', Icons.cancel_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _statusTab = TabController(length: _tabLabels.length, vsync: this);
    _statusTab.addListener(() {
      if (!_statusTab.indexIsChanging) {
        ref.read(gameProvider.notifier).setFilter(_filters[_statusTab.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).setCategoryFilter(null);
      ref.read(gameProvider.notifier).fetchGames(refresh: true);
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  @override
  void dispose() {
    _statusTab.dispose();
    super.dispose();
  }

  void _showCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateGameSheet(),
    );
  }

  void _openDetail(BuildContext context, GameEntity game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GameDetailSheet(game: game),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final currentUserId = ref.watch(authNotifierProvider).user?.userId;
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.profile;

    // Build a set of joined + created game IDs for quick lookup
    final joinedGameIds = <String>{
      ...state.myJoinedGames.map((g) => g.id),
      ...state.myCreatedGames.map((g) => g.id),
    };
    final joinedCount = joinedGameIds.length;
    final createdGameIds = <String>{...state.myCreatedGames.map((g) => g.id)};

    final sportFiltered = _selectedSport == 'All'
        ? state.filteredGames
        : state.filteredGames.where((g) => g.sport == _selectedSport).toList();
    final displayed = _showJoinedOnly
        ? sportFiltered.where((g) {
            if (joinedGameIds.contains(g.id)) return true;
            if (currentUserId == null) return false;
        return g.isCreator(currentUserId) ||
          g.isParticipant(currentUserId);
          }).toList()
        : sportFiltered;

    Future<void> confirmDelete(String gameId) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Game'),
          content: const Text(
              'Are you sure you want to permanently delete this game? This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await ref.read(gameProvider.notifier).deleteGame(gameId);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Gradient SliverAppBar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            floating: false,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Discover Games',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.games.length} game${state.games.length == 1 ? "" : "s"} available',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _GradientButton(
                      icon: Icons.add,
                      label: 'Host',
                      onTap: () => _showCreate(context),
                    ),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: profile?.avatar != null && profile!.avatar!.isNotEmpty
                      ? NetworkImage(profile.avatar!)
                      : null,
                  child: profile?.avatar == null || profile!.avatar!.isEmpty
                      ? Text(
                          profile?.fullName?.isNotEmpty == true
                              ? profile!.fullName![0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Games',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Host a game',
                  onPressed: () => _showCreate(context),
                ),
              ],
            ),
          ),

          // ── Category cards ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  _CategoryCard(
                    label: 'All Games',
                    icon: Icons.sports_esports,
                    count: state.games.length,
                    selected: !_showJoinedOnly,
                    color: AppColors.primary,
                    onTap: () {
                      ref.read(gameProvider.notifier).setCategoryFilter(null);
                      setState(() => _showJoinedOnly = false);
                    },
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _CategoryCard(
                    label: 'Joined Games',
                    icon: Icons.group_rounded,
                    count: joinedCount,
                    selected: _showJoinedOnly,
                    color: AppColors.info,
                    onTap: () {
                      ref.read(gameProvider.notifier).setCategoryFilter(null);
                      setState(() => _showJoinedOnly = true);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Sport filter chips ─────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                padding:
                    EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: _sports.length,
                separatorBuilder: (_, _) =>
                    SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final s = _sports[i];
                  final sel = _selectedSport == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSport = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md + 2,
                          vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primaryDark
                            : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.circle),
                        border: Border.all(
                          color: sel
                              ? AppColors.primaryDark
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sportIcons[s] ?? Icons.sports,
                            size: 14,
                            color: sel
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Status tabs ────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBar(
              tabBar: TabBar(
                controller: _statusTab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                dividerColor: AppColors.border,
                tabs: _tabLabels
                    .map((t) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.$2, size: 14),
                              const SizedBox(width: 5),
                              Text(t.$1,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              backgroundColor: AppColors.background,
            ),
          ),
        ],

        // ── Game list ────────────────────────────────────────────
        body: state.isLoading && state.games.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary))
            : displayed.isEmpty
                ? _EmptyGamesView(
                    sport: _selectedSport,
                  category: _showJoinedOnly ? 'joined' : state.categoryFilter,
                    onRefresh: () async {
                      await ref.read(gameProvider.notifier).fetchGames(refresh: true);
                      await ref.read(gameProvider.notifier).fetchMyJoinedGames();
                      await ref.read(gameProvider.notifier).fetchMyCreatedGames();
                    },
                    onCreate: () => _showCreate(context),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await ref.read(gameProvider.notifier).fetchGames(refresh: true);
                      await ref.read(gameProvider.notifier).fetchMyJoinedGames();
                      await ref.read(gameProvider.notifier).fetchMyCreatedGames();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.sm, AppSpacing.md, 80),
                      itemCount:
                          displayed.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == displayed.length) {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) {
                            ref
                                .read(gameProvider.notifier)
                                .fetchGames();
                          });
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          );
                        }
                        final game = displayed[i];
                        final isAlreadyJoined = currentUserId != null && (
                          joinedGameIds.contains(game.id) ||
                          game.isCreator(currentUserId) ||
                          game.isParticipant(currentUserId)
                        );
                        final isAlreadyCreator = currentUserId != null &&
                            createdGameIds.contains(game.id);
                        return GameCard(
                          game: game,
                          currentUserId: currentUserId,
                          isAlreadyJoined: isAlreadyJoined,
                          isAlreadyCreator: isAlreadyCreator,
                          onTap: () =>
                              _openDetail(context, game),
                            onJoin: () => ref
                              .read(gameProvider.notifier)
                              .joinGame(game.id),
                          onLeave: () async {
                              final result = await ref
                                  .read(gameProvider.notifier)
                                  .leaveGame(game.id);
                              if (result != null) {
                                ref.read(chatProvider.notifier).leaveRoom(game.id);
                              }
                            },
                          onCancel: () => ref
                              .read(gameProvider.notifier)
                              .cancelGame(game.id),
                          onDelete: () => confirmDelete(game.id),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky tab bar delegate
// ─────────────────────────────────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const _StickyTabBar(
      {required this.tabBar, required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _StickyTabBar old) =>
      tabBar != old.tabBar || backgroundColor != old.backgroundColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? color : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 0 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: selected ? Colors.white : color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient host button (shown in expanded header)
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradientButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.circle),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state view
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyGamesView extends StatelessWidget {
  final String sport;
  final String? category;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const _EmptyGamesView({
    required this.sport,
    required this.category,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final desc = [
      if (sport != 'All') sport,
      if (category != null) category!.toLowerCase(),
    ].join(' ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_esports_outlined,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              desc.isNotEmpty ? 'No $desc games found' : 'No games found',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to host a game!',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Host Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _GameDetailSheet extends ConsumerWidget {
  final GameEntity game;
  const _GameDetailSheet({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: EdgeInsets.all(AppSpacing.xl),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Badges row
            Row(
              children: [
                _Pill(
                  icon: game.isOnline ? Icons.wifi : Icons.location_on,
                  label: game.category,
                  color: game.isOnline ? AppColors.info : AppColors.success,
                ),
                const SizedBox(width: 8),
                _Pill(
                  icon: Icons.sports,
                  label: game.sport,
                  color: AppColors.primary,
                ),
                const Spacer(),
                _StatusBadge(game.status),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Title
            Text(game.title,
                style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            SizedBox(height: AppSpacing.xs),
            Text('Hosted by ${game.creatorName}',
                style: tt.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            SizedBox(height: AppSpacing.md),

            if (game.description.isNotEmpty)
              Text(game.description,
                  style: tt.bodyMedium?.copyWith(
                      color: AppColors.textSecondary, height: 1.5)),

            SizedBox(height: AppSpacing.xl),

            // Info rows
            _InfoRow(icon: Icons.group_outlined,
                label:
                    '${game.currentPlayers} / ${game.maxPlayers} players'),
            if (game.startTime != null)
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: game.startTime.toString().substring(0, 16)),
            if (!game.isOnline && game.location?.address != null)
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: game.location!.address!),
            _InfoRow(
                icon: Icons.info_outline,
                label: 'Status: ${game.status.name}'),

            // Tags
            if (game.tags.isNotEmpty) ...[
              SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: game.tags
                    .map((tag) => Chip(
                          label: Text(tag,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.surfaceLight,
                          side: const BorderSide(color: AppColors.border),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],

            // Participants
            if (game.participants.isNotEmpty) ...[
              SizedBox(height: AppSpacing.xl),
              Text('Participants',
                  style: tt.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: AppSpacing.sm),
              ...game.participants
                  .where((p) => p.status == ParticipantStatus.ACTIVE)
                  .map((p) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.primaryWithOpacity(0.1),
                          backgroundImage: p.avatar != null
                              ? NetworkImage(p.avatar!)
                              : null,
                          child: p.avatar == null
                              ? Text(
                                  p.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                )
                              : null,
                        ),
                        title: Text(p.displayName,
                            style: tt.bodyMedium),
                      )),
            ],

            SizedBox(height: AppSpacing.xxl),

            // Action button
            if (game.isOpen)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Join Game',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: () {
                    ref.read(gameProvider.notifier).joinGame(game.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ),
            if (game.isEnded || game.isCancelled)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  icon: Icon(game.isEnded
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined),
                  label: Text(
                      game.isEnded ? 'Game Ended' : 'Game Cancelled'),
                  onPressed: null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.circle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GameStatus status;
  const _StatusBadge(this.status);

  Color get _color => switch (status) {
        GameStatus.OPEN => AppColors.success,
        GameStatus.FULL => AppColors.warning,
        GameStatus.ENDED => AppColors.info,
        GameStatus.CANCELLED => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: TextStyle(
            color: _color,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

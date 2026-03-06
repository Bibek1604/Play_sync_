import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../widgets/create_game_sheet.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';
import '../../../profile/presentation/viewmodel/profile_notifier.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});
  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage>
    with SingleTickerProviderStateMixin {
  late final TabController _statusTab;
  final String _selectedSport = 'All';
  final bool _showJoinedOnly = false;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Build a set of joined + created game IDs for quick lookup
    final joinedGameIds = <String>{
      ...state.myJoinedGames.map((g) => g.id),
      ...state.myCreatedGames.map((g) => g.id),
    };
    final joinedCount = joinedGameIds.length;
    final createdGameIds = <String>{...state.myCreatedGames.map((g) => g.id)};

    final sportFiltered = state.filteredGames;
    final displayed = sportFiltered;

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
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1E293B), AppColors.backgroundDark]
              : [const Color(0xFFF0F9FF), Colors.white],
            stops: const [0.0, 0.4],
          ),
        ),
        child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 200,
            backgroundColor: const Color(0xFF0284C7),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Signature Sky-Blue Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                      ),
                    ),
                  ),
                  // Layer 2: Signature Mixture Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Layer 3: Texture
                  Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/pattern_bg.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  // Layer 4: Themed Icon
                  Positioned(
                    top: 55,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
              title: const Text(
                'My Sessions',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // ── Hero Section with stats ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${profile?.level ?? 1}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.fullName?.split(' ')[0] ?? 'Player',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$joinedCount Games Joined',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _CircleBadge(),
                  ],
                ),
              ),
            ),
          ),
          
          // ── Tabs ──────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _statusTab,
                isScrollable: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                tabs: _tabLabels.map((t) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$2, size: 16),
                      const SizedBox(width: 8),
                      Text(t.$1),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
        body: state.isLoading && state.games.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                    color: theme.colorScheme.primary))
            : displayed.isEmpty
                ? _EmptyGamesView(
                    onRefresh: () async {
                      await ref.read(gameProvider.notifier).fetchGames(refresh: true);
                      await ref.read(gameProvider.notifier).fetchMyJoinedGames();
                      await ref.read(gameProvider.notifier).fetchMyCreatedGames();
                    },
                    onCreate: () => _showCreate(context),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    onRefresh: () async {
                      await ref.read(gameProvider.notifier).fetchGames(refresh: true);
                      await ref.read(gameProvider.notifier).fetchMyJoinedGames();
                      await ref.read(gameProvider.notifier).fetchMyCreatedGames();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
                          return Center(
                                child: CircularProgressIndicator(
                                    color: theme.colorScheme.primary));
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
              ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _CircleBadge extends StatelessWidget {
  const _CircleBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.stars_rounded, color: Colors.white, size: 32),
      ),
    );
  }
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
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? color : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? color : theme.dividerColor,
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
                      : theme.colorScheme.onSurface,
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
                      : theme.colorScheme.onSurfaceVariant,
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
          borderRadius: BorderRadius.circular(24),
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
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const _EmptyGamesView({
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports_esports_outlined,
                  size: 56, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No games found',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to host a game!',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Host Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Badges row
            Row(
              children: [
                _Pill(
                  icon: game.isOnline ? Icons.wifi : Icons.location_on,
                  label: game.category,
                  color: game.isOnline ? theme.colorScheme.secondary : theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                _Pill(
                  icon: Icons.sports,
                  label: game.sport,
                  color: theme.colorScheme.primary,
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
                    color: theme.colorScheme.onSurface)),
            SizedBox(height: AppSpacing.xs),
            Text('Hosted by ${game.creatorName}',
                style: tt.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            SizedBox(height: AppSpacing.md),

            if (game.description.isNotEmpty)
              Text(game.description,
                  style: tt.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, height: 1.5)),

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
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          side: BorderSide(color: theme.dividerColor),
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
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          backgroundImage: p.avatar != null
                              ? NetworkImage(p.avatar!)
                              : null,
                          child: p.avatar == null
                              ? Text(
                                  p.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                      color: theme.colorScheme.primary,
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
                    backgroundColor: theme.colorScheme.primary,
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
        borderRadius: BorderRadius.circular(24),
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: AppSpacing.md),
          Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GameStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      GameStatus.OPEN => theme.colorScheme.primary,
      GameStatus.FULL => theme.colorScheme.tertiary,
      GameStatus.ENDED => theme.colorScheme.secondary,
      GameStatus.CANCELLED => theme.colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

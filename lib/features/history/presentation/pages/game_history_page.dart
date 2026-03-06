import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../widgets/history_stats_card.dart';
import '../../../profile/presentation/viewmodel/profile_notifier.dart';
import '../../../game/presentation/providers/game_notifier.dart';
import '../../../game/domain/entities/game_entity.dart';
import '../providers/history_notifier.dart';
import '../../domain/entities/game_history.dart';
import '../../../game/presentation/pages/game_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/app_drawer.dart';
/// Game History Page — shows the logged-in user's history, with tabs for
/// All · Created · Joined.
class GameHistoryPage extends ConsumerStatefulWidget {
  const GameHistoryPage({super.key});

  @override
  ConsumerState<GameHistoryPage> createState() => _GameHistoryPageState();
}

class _GameHistoryPageState extends ConsumerState<GameHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).fetchHistory();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<void> _refreshAll() async {
    await ref.read(historyProvider.notifier).fetchHistory();
    await ref.read(gameProvider.notifier).fetchMyCreatedGames();
    await ref.read(gameProvider.notifier).fetchMyJoinedGames();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final histState = ref.watch(historyProvider);
    final gameState = ref.watch(gameProvider);
    final profile = ref.watch(profileNotifierProvider).profile;
    final authUser = ref.watch(authNotifierProvider).user;

    final displayName = profile?.fullName ?? authUser?.fullName ?? 'You';
    final email = profile?.email ?? authUser?.email ?? '';
    final avatarUrl = profile?.avatar;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            floating: false,
            expandedHeight: 240,
            leading: Center(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                  ],
                ),
                child: IconButton(
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  color: isDark ? Colors.white : AppColors.primary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _UserBanner(
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
                histState: histState,
                gameState: gameState,
                isDark: isDark,
              ),
            ),
            title: Text(
              'Game History',
              style: TextStyle(
                color: isDark ? AppColors.secondary : AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                color: AppColors.textSecondary,
                tooltip: 'Refresh',
                onPressed: _refreshAll,
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 14,
                  letterSpacing: -0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'All History'),
                Tab(text: 'Created'),
                Tab(text: 'Joined'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            // ── All History ───────────────────────────────────────────────
            _AllHistoryTab(state: histState, isDark: isDark,
                onRefresh: () => ref.read(historyProvider.notifier).fetchHistory(),
                onLoadMore: () => ref.read(historyProvider.notifier).loadMore()),

            // ── Created ───────────────────────────────────────────────────
            _GameEntityTab(
              games: gameState.myCreatedGames,
              isLoading: gameState.isLoading,
              isDark: isDark,
              emptyIcon: Icons.add_circle_outline,
              emptyLabel: 'No games created yet',
              emptySubLabel: 'Games you host will appear here',
              roleLabel: 'Creator',
              roleColor: AppColors.primary,
              onRefresh: () => ref.read(gameProvider.notifier).fetchMyCreatedGames(),
            ),

            // ── Joined ────────────────────────────────────────────────────
            _GameEntityTab(
              games: gameState.myJoinedGames,
              isLoading: gameState.isLoading,
              isDark: isDark,
              emptyIcon: Icons.sports_esports_outlined,
              emptyLabel: 'No joined games yet',
              emptySubLabel: 'Games you join will appear here',
              roleLabel: 'Participant',
              roleColor: AppColors.info,
              onRefresh: () => ref.read(gameProvider.notifier).fetchMyJoinedGames(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User banner ────────────────────────────────────────────────────────────────

class _UserBanner extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarUrl;
  final HistoryState histState;
  final GameState gameState;
  final bool isDark;

  const _UserBanner({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.histState,
    required this.gameState,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── All-history tab ────────────────────────────────────────────────────────────

class _AllHistoryTab extends StatelessWidget {
  final HistoryState state;
  final bool isDark;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;

  const _AllHistoryTab({
    required this.state,
    required this.isDark,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.error != null && state.history.isEmpty) {
      return _ErrorRetry(message: state.error!, onRetry: onRefresh, isDark: isDark);
    }
    if (state.history.isEmpty) {
      return _EmptyTab(
        icon: Icons.history,
        label: 'No game history yet',
        subLabel: 'Games you played will appear here',
        isDark: isDark,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: state.history.length + 1 + (state.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          // ── Stats card at top ──
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HistoryStatsCard(
                total: state.totalGames,
                ended: state.endedGames,
                cancelled: state.cancelledGames,
                active: state.activeGames,
              ),
            );
          }
          final idx = i - 1;
          if (idx == state.history.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TextButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load more'),
                    ),
            );
          }
          return _HistoryCard(history: state.history[idx], isDark: isDark);
        },
      ),
    );
  }
}

// ── GameEntity tab (Created / Joined) ─────────────────────────────────────────

class _GameEntityTab extends StatelessWidget {
  final List<GameEntity> games;
  final bool isLoading;
  final bool isDark;
  final IconData emptyIcon;
  final String emptyLabel;
  final String emptySubLabel;
  final String roleLabel;
  final Color roleColor;
  final Future<void> Function() onRefresh;

  const _GameEntityTab({
    required this.games,
    required this.isLoading,
    required this.isDark,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.emptySubLabel,
    required this.roleLabel,
    required this.roleColor,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && games.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (games.isEmpty) {
      return _EmptyTab(
          icon: emptyIcon, label: emptyLabel, subLabel: emptySubLabel, isDark: isDark);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: games.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PremiumGameHistoryCard(
            game: games[i],
            isDark: isDark,
            roleLabel: roleLabel,
            roleColor: roleColor,
          ),
        ),
      ),
    );
  }
}

// ── History card (All tab) ────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final GameHistory history;
  final bool isDark;

  const _HistoryCard({required this.history, required this.isDark});

  static final _dateFmt = DateFormat('MMM d, yyyy');

  Color _statusColor(String status) => switch (status) {
        'OPEN' => AppColors.success,
        'FULL' => AppColors.warning,
        'ENDED' => AppColors.info,
        'CANCELLED' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(history.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameDetailPage(gameId: history.gameId)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner section
            SliverHistoryBanner(
              imageUrl: history.gameInfo.imageUrl,
              status: history.status,
              statusColor: sc,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          history.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Chip(label: history.category, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Hosted by ${history.gameInfo.creatorName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${history.gameInfo.currentPlayers}/${history.gameInfo.maxPlayers}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (history.myParticipation.joinedAt != null)
                        Text(
                          _dateFmt.format(history.myParticipation.joinedAt!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverHistoryBanner extends StatelessWidget {
  final String? imageUrl;
  final String status;
  final Color statusColor;
  final bool isDark;

  const SliverHistoryBanner({
    super.key,
    this.imageUrl,
    required this.status,
    required this.statusColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
              errorWidget: (_, __, ___) => _Placeholder(isDark: isDark),
            )
          else
            _Placeholder(isDark: isDark),
          
          // Gradient Scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          
          // Status Chip
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool isDark;
  const _Placeholder({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      child: Icon(Icons.videogame_asset_outlined, color: isDark ? Colors.white12 : Colors.black12, size: 40),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PremiumGameHistoryCard extends StatelessWidget {
  final GameEntity game;
  final bool isDark;
  final String roleLabel;
  final Color roleColor;

  const _PremiumGameHistoryCard({
    required this.game,
    required this.isDark,
    required this.roleLabel,
    required this.roleColor,
  });

  static final _dateFmt = DateFormat('MMM d, yyyy');

  Color _statusColor(GameStatus s) => switch (s) {
        GameStatus.OPEN => AppColors.success,
        GameStatus.FULL => AppColors.warning,
        GameStatus.ENDED => AppColors.info,
        GameStatus.CANCELLED => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(game.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameDetailPage(gameId: game.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            if (!isDark)
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SliverHistoryBanner(
              imageUrl: game.imageUrl,
              status: game.status.name,
              statusColor: sc,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          game.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Chip(label: roleLabel, color: roleColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(game.isOnline ? Icons.public_rounded : Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${game.sport} · ${game.category}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${game.currentPlayers}/${game.maxPlayers} players',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (game.startTime != null)
                        Text(
                          _dateFmt.format(game.startTime!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final bool isDark;
  const _EmptyTab(
      {required this.icon,
      required this.label,
      required this.subLabel,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.secondary : AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text(subLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorRetry(
      {required this.message, required this.onRetry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? AppColors.secondary : AppColors.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

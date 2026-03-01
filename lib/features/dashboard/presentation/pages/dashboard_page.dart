import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/app/routes/app_routes.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/game/domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game/presentation/pages/game_detail_page.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_notifier.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileNotifierProvider.notifier).getProfile();
      ref.read(gameProvider.notifier).fetchGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final gameState    = ref.watch(gameProvider);

    final profile      = profileState.profile;
    final offlineGames = gameState.games.where((g) => g.category == 'OFFLINE').take(3).toList();
    final onlineGames  = gameState.games.where((g) => g.category == 'ONLINE').take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PlaySync'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textSecondary),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.read(profileNotifierProvider.notifier).getProfile(),
            ref.read(gameProvider.notifier).fetchGames(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome card ───────────────────────────────────────
              _WelcomeCard(
                userName: profile?.fullName ??
                    authState.user?.fullName ??
                    'Gamer',
                avatar: profile?.avatar,
                level: profile?.level ?? 1,
                xp: profile?.xp ?? 0,
              ),

              const SizedBox(height: 20),

              // ── Stats ──────────────────────────────────────────────
              if (profile != null) ...[
                _QuickStats(
                  totalGames: profile.totalGames,
                  wins: profile.wins,
                  winRate: profile.winRate,
                ),
                const SizedBox(height: 24),
              ],

              // ── CTA row ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _CtaButton(
                      icon: Icons.search_rounded,
                      label: 'Find Now',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.offlineGames),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CtaButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Create Game',
                      color: AppColors.success,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.onlineGames),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Quick Actions ──────────────────────────────────────
              const _Label('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.wifi_off_rounded,
                      title: 'Offline',
                      subtitle: 'Local matches',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.offlineGames),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.wifi_rounded,
                      title: 'Online',
                      subtitle: 'Play remotely',
                      color: AppColors.info,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.onlineGames),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.history_rounded,
                      title: 'History',
                      subtitle: 'Past games',
                      color: AppColors.warning,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.gameHistory),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.leaderboard_rounded,
                      title: 'Rankings',
                      subtitle: 'Leaderboard',
                      color: AppColors.success,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.rankings),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Offline Games ──────────────────────────────────────
              _SectionHeader(
                title: 'Offline Games',
                onSeeAll: () =>
                    Navigator.pushNamed(context, AppRoutes.offlineGames),
              ),
              const SizedBox(height: 10),
              if (gameState.isLoading)
                const _LoadingTile()
              else if (offlineGames.isEmpty)
                _EmptySection(
                  label: 'No offline games yet',
                  onBrowse: () =>
                      Navigator.pushNamed(context, AppRoutes.offlineGames),
                )
              else
                ...offlineGames.map((g) => _GameTile(game: g)),

              const SizedBox(height: 24),

              // ── Online Games ───────────────────────────────────────
              _SectionHeader(
                title: 'Online Games',
                onSeeAll: () =>
                    Navigator.pushNamed(context, AppRoutes.onlineGames),
              ),
              const SizedBox(height: 10),
              if (gameState.isLoading)
                const _LoadingTile()
              else if (onlineGames.isEmpty)
                _EmptySection(
                  label: 'No online games yet',
                  onBrowse: () =>
                      Navigator.pushNamed(context, AppRoutes.onlineGames),
                )
              else
                ...onlineGames.map((g) => _GameTile(game: g)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Label(title),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('See All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primary)));
}

// ── Welcome Card ───────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final String userName;
  final String? avatar;
  final int level;
  final int xp;
  const _WelcomeCard(
      {required this.userName,
      this.avatar,
      required this.level,
      required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: (avatar != null && avatar!.isNotEmpty)
                ? NetworkImage(avatar!)
                : null,
            child: (avatar == null || avatar!.isEmpty)
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  'Lvl $level',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                Text(
                  '$xp XP',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Stats ────────────────────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  final int totalGames;
  final int wins;
  final double winRate;
  const _QuickStats(
      {required this.totalGames, required this.wins, required this.winRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
            icon: Icons.sports_esports_outlined,
            label: 'Games',
            value: '$totalGames'),
        const SizedBox(width: 10),
        _StatChip(icon: Icons.emoji_events_outlined, label: 'Wins', value: '$wins'),
        const SizedBox(width: 10),
        _StatChip(
            icon: Icons.percent_rounded,
            label: 'Win rate',
            value: '${(winRate * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── CTA Button ─────────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CtaButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9.5, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ── Empty Section ──────────────────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String label;
  final VoidCallback onBrowse;
  const _EmptySection({required this.label, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.sports_esports_outlined,
              size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onBrowse,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Browse'),
          ),
        ],
      ),
    );
  }
}

// ── Game Tile ──────────────────────────────────────────────────────────────────

class _GameTile extends StatelessWidget {
  final GameEntity game;
  const _GameTile({required this.game});

  Color _statusColor() {
    switch (game.status) {
      case GameStatus.OPEN:
        return AppColors.success;
      case GameStatus.FULL:
        return AppColors.warning;
      case GameStatus.ENDED:
        return AppColors.textTertiary;
      case GameStatus.CANCELLED:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GameDetailPage(gameId: game.id, preloadedGame: game)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                      '${game.sport} · ${game.currentPlayers}/${game.maxPlayers} players',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(game.status.name,
                  style: TextStyle(
                      color: sc,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

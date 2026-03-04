import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/app/routes/app_routes.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';
import 'package:play_sync_new/core/constants/app_spacing.dart';
import 'package:play_sync_new/core/widgets/app_drawer.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_notifier.dart';
import 'package:play_sync_new/features/profile/presentation/viewmodel/profile_notifier.dart';
import '../widgets/quick_action_widget.dart';
import '../widgets/game_tile_widget.dart';

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
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String gameId) async {
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
      final ok = await ref.read(gameProvider.notifier).deleteGame(gameId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Game deleted' : (ref.read(gameProvider).error ?? 'Failed to delete')),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use selective watching for better performance
    final profile      = ref.watch(profileNotifierProvider.select((s) => s.profile));
    final joinedGames  = ref.watch(gameProvider.select((s) => s.myJoinedGames));
    final createdGames = ref.watch(gameProvider.select((s) => s.myCreatedGames));
    final isLoading    = ref.watch(gameProvider.select((s) => s.isLoading));
    final currentUserId = ref.watch(authNotifierProvider.select((s) => s.user?.userId));
    final authUser     = ref.watch(authNotifierProvider.select((s) => s.user));

    final size = MediaQuery.sizeOf(context);
    final bool isWide = size.width > 600;
    final horizontalPadding = isWide ? size.width * 0.1 : AppSpacing.space20;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'user_avatar',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: profile?.avatar != null && profile!.avatar!.isNotEmpty
                    ? NetworkImage(profile.avatar!)
                    : null,
                child: profile?.avatar == null || profile!.avatar!.isEmpty
                    ? Text(
                        profile?.fullName?.isNotEmpty == true
                            ? profile!.fullName![0].toUpperCase()
                            : authUser?.fullName?.isNotEmpty == true
                                ? authUser!.fullName![0].toUpperCase()
                                : 'P',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            const Text(
              'PlaySync',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.read(profileNotifierProvider.notifier).getProfile(),
            ref.read(gameProvider.notifier).fetchMyJoinedGames(),
            ref.read(gameProvider.notifier).fetchMyCreatedGames(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.space24, horizontalPadding, 0),
              sliver: SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome card ───────────────────────────────────────
                      _WelcomeCard(
                        userName: profile?.fullName ?? authUser?.fullName ?? 'Gamer',
                        avatar: profile?.avatar,
                        level: profile?.level ?? 1,
                        xp: profile?.xp ?? 0,
                      ),
  
                      const SizedBox(height: AppSpacing.space24),
  
                      // ── Quick Stats ──────────────────────────────────────────────
                      if (profile != null) ...[
                        _QuickStats(
                          totalGames: profile.totalGames,
                          wins: profile.wins,
                          winRate: profile.winRate,
                        ),
                        const SizedBox(height: AppSpacing.space24),
                      ],
  
                      // ── CTA Buttons ────────────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _CtaButton(
                              icon: Icons.search_rounded,
                              label: 'Find Games',
                              color: AppColors.primary,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.availableGames),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: _CtaButton(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Create Game',
                              color: AppColors.success,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
                            ),
                          ),
                        ],
                      ),
  
                      const SizedBox(height: AppSpacing.space32),
  
                      // ── Quick Actions Grid ─────────────────────────────────
                      const QuickActionWidget(),
  
                      const SizedBox(height: AppSpacing.space32),
  
                      // ── My Created Sessions Header ────────────────────────
                      _SectionHeader(
                        title: 'My Created Sessions',
                        onSeeAll: () => Navigator.pushNamed(context, AppRoutes.gameHistory),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                    ],
                  ),
                ),
              ),
            ),

            // ── My Created Sessions List (LAZY) ──────────────────────────
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: (isLoading && createdGames.isEmpty)
                  ? const SliverToBoxAdapter(child: _LoadingTile())
                  : createdGames.isEmpty
                      ? SliverToBoxAdapter(
                          child: _EmptySection(
                            label: 'No active creations.',
                            onBrowse: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => GameTileWidget(
                              game: createdGames[index],
                              currentUserId: currentUserId,
                              onDelete: () => _confirmDelete(context, ref, createdGames[index].id),
                            ),
                            childCount: createdGames.length,
                          ),
                        ),
            ),

            // ── My Joined Games Header ─────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.space32, horizontalPadding, AppSpacing.space12),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'My Joined Games',
                  onSeeAll: () => Navigator.pushNamed(context, AppRoutes.gameHistory),
                ),
              ),
            ),

            // ── My Joined Games List (LAZY) ──────────────────────────────
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: (isLoading && joinedGames.isEmpty)
                  ? const SliverToBoxAdapter(child: _LoadingTile())
                  : joinedGames.isEmpty
                      ? SliverToBoxAdapter(
                          child: _EmptySection(
                            label: 'Ready to play?',
                            onBrowse: () => Navigator.pushNamed(context, AppRoutes.availableGames),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => GameTileWidget(
                              game: joinedGames[index],
                              currentUserId: currentUserId,
                            ),
                            childCount: joinedGames.length,
                          ),
                        ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space40)),
          ],
        ),
      ),
    );
  }
}

// ── Components ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('See All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      );
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(
          padding: EdgeInsets.all(AppSpacing.space24),
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)));
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
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radius24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 300;
          return Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: isNarrow ? 24 : 34,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: (avatar != null && avatar!.isNotEmpty)
                      ? NetworkImage(avatar!)
                      : null,
                  child: (avatar == null || avatar!.isEmpty)
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontSize: isNarrow ? 22 : 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.space20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: isNarrow ? 20 : 26,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radius20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LV $level',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.0),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp XP',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
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
            label: 'Total Games',
            value: '$totalGames'),
        const SizedBox(width: AppSpacing.space12),
        _StatChip(icon: Icons.emoji_events_outlined, label: 'Wins', value: '$wins'),
        const SizedBox(width: AppSpacing.space12),
        _StatChip(
            icon: Icons.auto_graph_rounded,
            label: 'Win Rate',
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space20, horizontal: AppSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radius20),
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary, 
                    fontSize: 10, 
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ── CTA Button ─────────────────────────────────────────────────────────────────

class _CtaButton extends StatefulWidget {
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
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radius16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.space10),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius24),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_esports_outlined,
                    size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
              ),
              const SizedBox(height: 16),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2)),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 140,
                  maxWidth: constraints.maxWidth * 0.7 > 200 ? 200 : constraints.maxWidth * 0.7,
                ),
                child: ElevatedButton(
                  onPressed: onBrowse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: const Text('Explore', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}

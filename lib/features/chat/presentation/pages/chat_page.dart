import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_notifier.dart';
import '../../../game/presentation/providers/game_notifier.dart';
import '../../../game/domain/entities/game_entity.dart';
import 'package:play_sync_new/features/game_chat/game_chat.dart';
import 'package:play_sync_new/core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/widgets/app_drawer.dart';

/// Chat page — shows game chats where the user is an active participant or creator.
/// Leaving a game or deleting a game automatically removes it from this list.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    // Load joined & created games so their chats appear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(chatProvider.notifier).fetchRooms(),
      ref.read(gameProvider.notifier).fetchMyJoinedGames(),
      ref.read(gameProvider.notifier).fetchMyCreatedGames(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final gameState = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.userId;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build the filtered game chat list:
    //  • Deduplicated by id
    //  • Only OPEN or FULL games (active games)
    //  • User must be logged in
    //  • User must be the CREATOR or an ACTIVE participant
    //  • If user left, isParticipant returns false (checks status == ACTIVE)
    //  • If game is deleted/ended/cancelled, it is excluded by status check
    final seen = <String>{};
    final gameChats = [
      ...gameState.myJoinedGames,
      ...gameState.myCreatedGames,
    ].where((g) {
      if (!seen.add(g.id)) return false;
      if (g.status != GameStatus.OPEN && g.status != GameStatus.FULL) return false;
      if (currentUserId == null) return false;
      return g.isCreator(currentUserId) || g.isParticipant(currentUserId);
    }).toList();

    final hasGameChats = gameChats.isNotEmpty;
    final isLoading = chatState.isLoadingRooms;

    final bgColor1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final bgColor2 = isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasGameChats
                ? _EmptyState(onRefresh: _refresh)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // ── Signature Header ────────────────────────────────
                        SliverAppBar(
                          pinned: true,
                          floating: false,
                          expandedHeight: 140,
                          backgroundColor: const Color(0xFF0284C7),
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          automaticallyImplyLeading: false,
                          flexibleSpace: FlexibleSpaceBar(
                            collapseMode: CollapseMode.pin,
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Layer 1: Gradient
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                                // Layer 2: Mixture Overlay
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
                                  top: 50,
                                  left: 20,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.forum_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: const Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.8,
                              ),
                            ),
                            titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                          ),
                        ),
                        // ── Content ─────────────────────────────────────────
                        _SectionHeader(
                          icon: Icons.sports_esports_rounded,
                          label: 'Active Arenas',
                          color: const Color(0xFF0284C7),
                          isDark: isDark,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          sliver: SliverList.separated(
                            itemCount: gameChats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final game = gameChats[i];
                              return _GameChatTile(
                                game: game,
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GameChatRoomPage(
                                      gameId: game.id,
                                      gameTitle: game.title,
                                      gameImageUrl: game.image,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a game to start\nchatting with other players.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRefresh,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('Refresh',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white70 : color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Game Chat Tile ───────────────────────────────────────────────────────────
// Pure chat-entry tile — tapping goes directly to the game chat room.
// There is NO "View Details" button here.

class _GameChatTile extends StatelessWidget {
  final GameEntity game;
  final VoidCallback onTap;
  final bool isDark;
  const _GameChatTile(
      {required this.game, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (game.status) {
      GameStatus.OPEN => const Color(0xFF10B981),
      GameStatus.FULL => const Color(0xFFF97316),
      GameStatus.ENDED => const Color(0xFF94A3B8),
      GameStatus.CANCELLED => const Color(0xFFEF4444),
    };

    final subtitle = '${game.currentPlayers}/${game.maxPlayers} players'
        '${game.sport.isNotEmpty ? ' · ${game.sport}' : ''}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // ── Avatar with live status dot ──────────────────────────
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2), width: 2),
                    image: (game.image != null && game.image!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(game.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (game.image == null || game.image!.isEmpty)
                      ? const Icon(Icons.sports_esports_rounded,
                          color: AppColors.primary, size: 24)
                      : null,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // ── Game title & player count ────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded,
                          size: 12,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Arrow — takes you straight to chat ──────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

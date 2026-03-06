import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_card.dart';
import '../../domain/entities/game_entity.dart';
import 'game_detail_page.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class EndedGamesPage extends ConsumerStatefulWidget {
  const EndedGamesPage({super.key});

  @override
  ConsumerState<EndedGamesPage> createState() => _EndedGamesPageState();
}

class _EndedGamesPageState extends ConsumerState<EndedGamesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).fetchGames(refresh: true);
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
      ref.read(gameProvider.notifier).fetchMyCreatedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final endedGames = () {
      final Set<String> allIds = {};
      final list = <GameEntity>[];
      
      // Collect all games and filter only ENDED
      final allAvailable = [
        ...state.games,
        ...state.myCreatedGames,
        ...state.myJoinedGames,
        ...state.filteredGames,
      ];

      for (final g in allAvailable) {
        if (!allIds.contains(g.id) && g.status == GameStatus.ENDED) {
          list.add(g);
          allIds.add(g.id);
        }
      }
      
      // Sort by end time or start time descending
      list.sort((a, b) => (b.startTime ?? b.createdAt).compareTo(a.startTime ?? a.createdAt));
      return list;
    }();

    final joinedGameIds = <String>{
      ...state.myJoinedGames.map((g) => g.id),
      ...state.myCreatedGames.map((g) => g.id),
    };
    final createdGameIds = <String>{...state.myCreatedGames.map((g) => g.id)};

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
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                        ),
                      ),
                    ),
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
                          Icons.event_available_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                title: const Text(
                  'Ended Games',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  onPressed: () => ref.read(gameProvider.notifier).fetchGames(refresh: true),
                ),
              ],
            ),
          ],
          body: Container(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            child: RefreshIndicator(
              color: const Color(0xFF0284C7),
              onRefresh: () async {
                await ref.read(gameProvider.notifier).fetchGames(refresh: true);
              },
              child: state.isLoading && endedGames.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : endedGames.isEmpty
                      ? _buildEmptyState(context, isDark)
                      : ListView.separated(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          itemCount: endedGames.length,
                          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) {
                            final game = endedGames[i];
                            final isAlreadyJoined = currentUserId != null && (
                              joinedGameIds.contains(game.id) ||
                              game.isCreator(currentUserId) ||
                              game.isParticipant(currentUserId)
                            );
                            final isAlreadyCreator = createdGameIds.contains(game.id) ||
                              (currentUserId != null && game.isCreator(currentUserId));

                            return GameCard(
                              game: game,
                              currentUserId: currentUserId,
                              isAlreadyJoined: isAlreadyJoined,
                              isAlreadyCreator: isAlreadyCreator,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameDetailPage(
                                    gameId: game.id,
                                    preloadedGame: game,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Ended Games',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Active games will appear here\nonce they are finished.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

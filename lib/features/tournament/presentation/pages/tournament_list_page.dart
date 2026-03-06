import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:play_sync_new/core/constants/app_colors.dart";
import "../../domain/entities/tournament_entity.dart";
import "../providers/tournament_notifier.dart";
import "../widgets/tournament_card.dart";

class TournamentListPage extends ConsumerStatefulWidget {
  const TournamentListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends ConsumerState<TournamentListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final n = ref.read(tournamentProvider.notifier);
      n.fetchTournaments(refresh: true);
      n.fetchMyTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentProvider);

    return Scaffold(
      // Light blue → white gradient background (matches user request)
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF), // very soft sky-blue top
              Colors.white,      // pure white bottom
            ],
            stops: [0.0, 0.35],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 130,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              shadowColor: Colors.black12,
              leading: const SizedBox.shrink(),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.emoji_events_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const Spacer(),
                              _RefreshBtn(onTap: () {
                                ref
                                    .read(tournamentProvider.notifier)
                                    .fetchTournaments(refresh: true);
                                ref
                                    .read(tournamentProvider.notifier)
                                    .fetchMyTournaments();
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 2),

                        ],
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  "Tournaments",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.4,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            if (state.isLoading && state.tournaments.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (state.tournaments.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.separated(
                  itemCount: state.tournaments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      TournamentCard(tournament: state.tournaments[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RefreshBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        ),
        child: const Icon(Icons.refresh_rounded,
            color: AppColors.primary, size: 18),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Tournaments Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Check back later for upcoming competitions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

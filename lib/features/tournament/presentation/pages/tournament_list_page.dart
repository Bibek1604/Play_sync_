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
  String _activeTab = "All";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(tournamentProvider.notifier);
      notifier.fetchTournaments(refresh: true);
      notifier.fetchMyTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tournamentProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    final List<TournamentEntity> tournaments = _filteredTournaments(state);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Tournaments",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: AppColors.primary),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: AppColors.primary),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          
          // Tabs for Categories
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildTab("All", _activeTab == "All", isDark),
                  _buildTab("Ongoing", _activeTab == "Ongoing", isDark),
                  _buildTab("Upcoming", _activeTab == "Upcoming", isDark),
                  _buildTab("My Tournaments", _activeTab == "My Tournaments", isDark),
                ],
              ),
            ),
          ),

          // Tournament List
          if (state.isLoading && tournaments.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null && tournaments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else if (tournaments.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  "No tournaments found",
                  style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TournamentCard(tournament: tournaments[index]),
                  childCount: tournaments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
          ? AppColors.primary
          : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      ),
    );
  }

  List<TournamentEntity> _filteredTournaments(TournamentState state) {
    switch (_activeTab) {
      case "Ongoing":
        return state.tournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
      case "Upcoming":
        return state.tournaments.where((t) => t.status == TournamentStatus.open).toList();
      case "My Tournaments":
        return state.myTournaments;
      default:
        return state.tournaments;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/value_objects/leaderboard_filter.dart';

// Simulated repository — replace with actual remote datasource
class LeaderboardRepository {
  Future<List<LeaderboardEntry>> fetchLeaderboard(LeaderboardFilter filter) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock data — replace with real API call
    return List.generate(20, (i) {
      return LeaderboardEntry(
        userId: 'user_$i',
        username: 'Player ${i + 1}',
        rank: i + 1,
        totalPoints: 5000 - (i * 200),
        gamesPlayed: 50 - i,
        gamesWon: 30 - i,
        winRate: (30 - i) / (50 - i),
        currentStreak: i < 3 ? 5 - i : 0,
        isCurrentUser: i == 4,
      );
    });
  }
}

final leaderboardRepoProvider = Provider((ref) => LeaderboardRepository());

// State
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardFilter filter;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const LeaderboardState({
    this.entries = const [],
    this.filter = const LeaderboardFilter(),
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardFilter? filter,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _repo;

  LeaderboardNotifier(this._repo) : super(const LeaderboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _repo.fetchLeaderboard(state.filter);
      state = state.copyWith(entries: entries, isLoading: false, hasMore: entries.length >= state.filter.limit);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeFilter(LeaderboardFilter filter) async {
    state = state.copyWith(filter: filter, entries: [], hasMore: true);
    await load();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextFilter = state.filter.copyWithNextPage();
    state = state.copyWith(isLoading: true);
    try {
      final more = await _repo.fetchLeaderboard(nextFilter);
      state = state.copyWith(
        entries: [...state.entries, ...more],
        filter: nextFilter,
        isLoading: false,
        hasMore: more.length >= nextFilter.limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.read(leaderboardRepoProvider));
});

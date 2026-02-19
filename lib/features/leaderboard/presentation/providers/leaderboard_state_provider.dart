import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:play_sync_new/features/leaderboard/presentation/providers/leaderboard_providers.dart';

/// Leaderboard State
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final String currentFilter; // 'global', 'friends', 'nearby'

  LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.currentFilter = 'global',
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    String? currentFilter,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }

  /// Get top 10 entries
  List<LeaderboardEntry> get top10 => entries.take(10).toList();

  /// Get top 3 entries
  List<LeaderboardEntry> get top3 => entries.take(3).toList();
}

/// Leaderboard Notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref ref;

  LeaderboardNotifier(this.ref) : super(LeaderboardState());

  /// Load leaderboard
  Future<void> loadLeaderboard({String filter = 'global'}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentFilter: filter,
    );

    try {
      final getLeaderboard = ref.read(getLeaderboardUseCaseProvider);
      final entries = await getLeaderboard(period: filter);

      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh leaderboard
  Future<void> refresh() async {
    await loadLeaderboard(filter: state.currentFilter);
  }

  /// Change filter
  Future<void> changeFilter(String filter) async {
    if (filter != state.currentFilter) {
      await loadLeaderboard(filter: filter);
    }
  }
}

/// Leaderboard State Provider
final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref);
});

/// Top 10 provider
final top10Provider = Provider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardProvider.select((state) => state.top10));
});

/// Top 3 provider (for podium display)
final top3Provider = Provider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardProvider.select((state) => state.top3));
});

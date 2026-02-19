import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:play_sync_new/features/leaderboard/domain/usecases/get_leaderboard.dart';
import 'package:play_sync_new/features/leaderboard/presentation/providers/leaderboard_providers.dart';

/// Leaderboard State
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Leaderboard Notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final GetLeaderboard _getLeaderboard;

  LeaderboardNotifier(this._getLeaderboard) : super(const LeaderboardState());

  Future<void> loadLeaderboard({
    String period = 'all',
    bool refresh = false,
  }) async {
    if (refresh) {
      state = const LeaderboardState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final entries = await _getLeaderboard(
        page: 1,
        limit: 50,
        period: period,
      );

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMore: entries.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore({String period = 'all'}) async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newEntries = await _getLeaderboard(
        page: nextPage,
        limit: 50,
        period: period,
      );

      state = state.copyWith(
        entries: [...state.entries, ...newEntries],
        isLoading: false,
        currentPage: nextPage,
        hasMore: newEntries.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh({String period = 'all'}) async {
    await loadLeaderboard(period: period, refresh: true);
  }
}

/// Leaderboard Notifier Provider
final leaderboardNotifierProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(
    ref.watch(getLeaderboardUseCaseProvider),
  );
});

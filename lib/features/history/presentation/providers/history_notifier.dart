import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/history/domain/entities/game_history.dart';
import 'package:play_sync_new/features/history/domain/entities/participation_stats.dart';
import 'package:play_sync_new/features/history/domain/usecases/get_count.dart';
import 'package:play_sync_new/features/history/domain/usecases/get_my_history.dart';
import 'package:play_sync_new/features/history/domain/usecases/get_stats.dart';
import 'package:play_sync_new/features/history/presentation/providers/history_providers.dart';

// State classes
class HistoryState {
  final List<GameHistory> history;
  final ParticipationStats? stats;
  final int? totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;

  HistoryState({
    this.history = const [],
    this.stats,
    this.totalCount,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  HistoryState copyWith({
    List<GameHistory>? history,
    ParticipationStats? stats,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return HistoryState(
      history: history ?? this.history,
      stats: stats ?? this.stats,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// History Notifier
class HistoryNotifier extends StateNotifier<HistoryState> {
  final GetMyHistory _getMyHistory;
  final GetStats _getStats;
  final GetCount _getCount;

  HistoryNotifier(
    this._getMyHistory,
    this._getStats,
    this._getCount,
  ) : super(HistoryState());

  Future<void> loadHistory({bool refresh = false}) async {
    if (refresh) {
      state = HistoryState(isLoading: true);
    } else if (state.isLoading || state.isLoadingMore) {
      return;
    }

    try {
      state = state.copyWith(
        isLoading: refresh,
        error: null,
      );

      final result = await _getMyHistory(page: 1, limit: 20);

      state = state.copyWith(
        history: result.history,
        currentPage: result.pagination.page,
        hasMore: result.pagination.hasNext,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);

      final nextPage = state.currentPage + 1;
      final result = await _getMyHistory(page: nextPage, limit: 20);

      state = state.copyWith(
        history: [...state.history, ...result.history],
        currentPage: result.pagination.page,
        hasMore: result.pagination.hasNext,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoadingMore: false,
      );
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _getStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Silently fail for stats
      print('Error loading stats: $e');
    }
  }

  Future<void> loadCount() async {
    try {
      final count = await _getCount();
      state = state.copyWith(totalCount: count);
    } catch (e) {
      // Silently fail for count
      print('Error loading count: $e');
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadHistory(refresh: true),
      loadStats(),
      loadCount(),
    ]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// History Notifier Provider
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(
    ref.watch(getMyHistoryUseCaseProvider),
    ref.watch(getStatsUseCaseProvider),
    ref.watch(getCountUseCaseProvider),
  );
});

// Provider
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(
    ref.watch(getMyHistoryUseCaseProvider),
    ref.watch(getStatsUseCaseProvider),
    ref.watch(getCountUseCaseProvider),
  );
});

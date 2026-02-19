import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/history/domain/entities/game_history.dart';
import 'package:play_sync_new/features/history/domain/entities/participation_stats.dart';
import 'package:play_sync_new/features/history/domain/repositories/history_repository.dart';
import 'package:play_sync_new/features/history/presentation/providers/history_providers.dart';

/// History State
class HistoryState {
  final List<GameHistory> history;
  final PaginationMeta? pagination;
  final ParticipationStats? stats;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  HistoryState({
    this.history = const [],
    this.pagination,
    this.stats,
    this.totalCount = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  HistoryState copyWith({
    List<GameHistory>? history,
    PaginationMeta? pagination,
    ParticipationStats? stats,
    int? totalCount,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return HistoryState(
      history: history ?? this.history,
      pagination: pagination ?? this.pagination,
      stats: stats ?? this.stats,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }

  bool get hasMore => pagination?.hasNext ?? false;
  bool get hasPrevious => pagination?.hasPrevious ?? false;
}

/// History Notifier
class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref ref;

  HistoryNotifier(this.ref) : super(HistoryState());

  /// Load history with optional filters
  Future<void> loadHistory({
    int page = 1,
    int limit = 10,
    String? status,
    bool append = false,
  }) async {
    if (append) {
      state = state.copyWith(isLoadingMore: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final getMyHistory = ref.read(getMyHistoryUseCaseProvider);
      final result = await getMyHistory(
        page: page,
        limit: limit,
        status: status,
      );

      state = state.copyWith(
        history: append ? [...state.history, ...result.history] : result.history,
        pagination: result.pagination,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoadingMore) {
      final nextPage = (state.pagination?.page ?? 0) + 1;
      await loadHistory(
        page: nextPage,
        limit: state.pagination?.limit ?? 10,
        append: true,
      );
    }
  }

  /// Refresh history
  Future<void> refresh() async {
    await loadHistory(page: 1);
  }

  /// Load statistics
  Future<void> loadStats() async {
    try {
      final getStats = ref.read(getStatsUseCaseProvider);
      final stats = await getStats();
      
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Stats loading failure doesn't affect main state
      print('Failed to load stats: $e');
    }
  }

  /// Load total count
  Future<void> loadCount() async {
    try {
      final getCount = ref.read(getCountUseCaseProvider);
      final count = await getCount();
      
      state = state.copyWith(totalCount: count);
    } catch (e) {
      print('Failed to load count: $e');
    }
  }

  /// Load all data
  Future<void> loadAll() async {
    await Future.wait([
      loadHistory(),
      loadStats(),
      loadCount(),
    ]);
  }
}

/// History State Provider
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

/// Filtered history providers
final completedGamesProvider = Provider<List<GameHistory>>((ref) {
  final historyState = ref.watch(historyProvider);
  return historyState.history.where((h) => h.status == 'completed').toList();
});

final activeGamesProvider = Provider<List<GameHistory>>((ref) {
  final historyState = ref.watch(historyProvider);
  return historyState.history.where((h) => h.status == 'active').toList();
});

final cancelledGamesProvider = Provider<List<GameHistory>>((ref) {
  final historyState = ref.watch(historyProvider);
  return historyState.history.where((h) => h.status == 'cancelled').toList();
});

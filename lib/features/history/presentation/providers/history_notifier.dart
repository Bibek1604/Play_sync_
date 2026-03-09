import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_history.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_client.dart';
class HistoryState extends Equatable {
  final List<GameHistory> history;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int page;

  // Stats from /history/stats or /history/count
  final int totalGames;
  final int activeGames;
  final int endedGames;
  final int cancelledGames;

  const HistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.page = 1,
    this.totalGames = 0,
    this.activeGames = 0,
    this.endedGames = 0,
    this.cancelledGames = 0,
  });

  HistoryState copyWith({
    List<GameHistory>? history,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasMore,
    int? page,
    int? totalGames,
    int? activeGames,
    int? endedGames,
    int? cancelledGames,
  }) {
    return HistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalGames: totalGames ?? this.totalGames,
      activeGames: activeGames ?? this.activeGames,
      endedGames: endedGames ?? this.endedGames,
      cancelledGames: cancelledGames ?? this.cancelledGames,
    );
  }

  @override
  List<Object?> get props =>
      [history, isLoading, error, hasMore, page, totalGames, activeGames, endedGames, cancelledGames];
}
class HistoryNotifier extends StateNotifier<HistoryState> {
  final ApiClient _apiClient;

  HistoryNotifier(this._apiClient) : super(const HistoryState()) {
    fetchHistory();
  }

  /// Fetch user's game history from backend: GET /history?page=&limit=
  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, clearError: true, page: 1, history: []);
    try {
      final resp = await _apiClient.get(
        ApiEndpoints.getHistory,
        queryParameters: {'page': 1, 'limit': 20},
      );
      final body = resp.data as Map<String, dynamic>;
      // Backend wraps: { success, message, data: { history: [], pagination: {} } }
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final rawList = (data['history'] as List? ?? [])
          .map((j) => GameHistory.fromJson(j as Map<String, dynamic>))
          .toList();

      // Filter: only show games where the current user actually participated
      final list = rawList.where((h) => h.myParticipation.joinedAt != null).toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final hasNext = pagination['hasNext'] as bool? ?? false;

      // Stats: count by game status (not participation status)
      final ended    = list.where((h) => h.status == 'ENDED').length;
      final cancelled = list.where((h) => h.status == 'CANCELLED').length;
      final active   = list.where((h) => h.status == 'OPEN' || h.status == 'FULL').length;

      state = state.copyWith(
        history: list,
        isLoading: false,
        hasMore: hasNext,
        totalGames: list.length,
        activeGames: active,
        endedGames: ended,
        cancelledGames: cancelled,
      );

      // Also fetch stats separately
      _fetchStats();
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : (e.response?.data is Map
              ? (e.response!.data['message'] ?? 'Failed to load history')
              : 'Failed to load history');
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchStats() async {
    try {
      final resp = await _apiClient.get(ApiEndpoints.getHistoryCount);
      final body = resp.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      state = state.copyWith(
        totalGames: data['count'] as int? ?? data['total'] as int? ?? state.totalGames,
      );
    } catch (_) {
      // Stats are optional — don't fail the whole page
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _apiClient.get(
        ApiEndpoints.getHistory,
        queryParameters: {'page': nextPage, 'limit': 20},
      );
      final body = resp.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final rawList = (data['history'] as List? ?? [])
          .map((j) => GameHistory.fromJson(j as Map<String, dynamic>))
          .toList();

      // Filter
      final list = rawList.where((h) => h.myParticipation.joinedAt != null).toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final hasNext = pagination['hasNext'] as bool? ?? false;

      state = state.copyWith(
        history: [...state.history, ...list],
        isLoading: false,
        hasMore: hasNext,
        page: nextPage,
      );
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : 'Failed to load more history';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HistoryNotifier(apiClient);
});

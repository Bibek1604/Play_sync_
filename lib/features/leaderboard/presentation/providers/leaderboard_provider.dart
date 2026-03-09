import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/value_objects/leaderboard_filter.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardFilter filter;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int totalEntries;

  const LeaderboardState({
    this.entries = const [],
    this.filter = const LeaderboardFilter(),
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.totalEntries = 0,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardFilter? filter,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasMore,
    int? totalEntries,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
    );
  }
}
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final ApiClient _apiClient;
  final String? _currentUserId;

  LeaderboardNotifier(this._apiClient, this._currentUserId)
      : super(const LeaderboardState()) {
    load();
  }

  /// Fetch leaderboard from backend: GET /leaderboard?page=&limit=&period=
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final filter = state.filter;
      final resp = await _apiClient.get(
        ApiEndpoints.getLeaderboard,
        queryParameters: {
          'page': filter.offset ~/ filter.limit + 1,
          'limit': filter.limit,
          if (filter.period == LeaderboardPeriod.monthly) 'period': 'monthly',
        },
      );

      final body = resp.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = (data['leaderboard'] as List? ?? [])
          .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
          .toList();

      // Mark current user
      final entries = list
          .map((e) => e.userId == _currentUserId
              ? e.copyWith(isCurrentUser: true)
              : e)
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final hasNext = pagination['hasNext'] as bool? ?? false;
      final total = pagination['total'] as int? ?? entries.length;

      state = state.copyWith(
        entries: entries,
        isLoading: false,
        hasMore: hasNext,
        totalEntries: total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> changeFilter(LeaderboardFilter filter) async {
    state = state.copyWith(filter: filter.copyWith(offset: 0), entries: [], hasMore: true);
    await load();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextFilter = state.filter.copyWithNextPage();
    state = state.copyWith(isLoading: true, filter: nextFilter);
    try {
      final resp = await _apiClient.get(
        ApiEndpoints.getLeaderboard,
        queryParameters: {
          'page': nextFilter.offset ~/ nextFilter.limit + 1,
          'limit': nextFilter.limit,
          if (nextFilter.period == LeaderboardPeriod.monthly) 'period': 'monthly',
        },
      );

      final body = resp.data as Map<String, dynamic>;
      final data = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = (data['leaderboard'] as List? ?? [])
          .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
          .toList();

      final entries = list
          .map((e) => e.userId == _currentUserId
              ? e.copyWith(isCurrentUser: true)
              : e)
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final hasNext = pagination['hasNext'] as bool? ?? false;

      state = state.copyWith(
        entries: [...state.entries, ...entries],
        isLoading: false,
        hasMore: hasNext,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  // Try to get current user ID from auth state
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.userId;
  return LeaderboardNotifier(apiClient, userId);
});

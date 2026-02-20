import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/game_history.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_client.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class HistoryState extends Equatable {
  final List<GameHistory> history;
  final bool isLoading;
  final String? error;

  // Stats
  final int totalGames;
  final int wins;
  final int losses;
  final int draws;

  const HistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.totalGames = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  HistoryState copyWith({
    List<GameHistory>? history,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? totalGames,
    int? wins,
    int? losses,
    int? draws,
  }) {
    return HistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
    );
  }

  @override
  List<Object?> get props =>
      [history, isLoading, error, totalGames, wins, losses, draws];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class HistoryNotifier extends StateNotifier<HistoryState> {
  final ApiClient _apiClient;

  HistoryNotifier(this._apiClient) : super(const HistoryState()) {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _apiClient.get(ApiEndpoints.getHistory);
      final data = resp.data as Map<String, dynamic>;
      final list = (data['history'] as List? ?? data['data'] as List? ?? [])
          .map((j) => GameHistory.fromJson(j as Map<String, dynamic>))
          .toList();

      // Calculate stats
      final wins = list.where((h) => h.result == 'win').length;
      final losses = list.where((h) => h.result == 'loss').length;
      final draws = list.where((h) => h.result == 'draw').length;

      state = state.copyWith(
        history: list,
        isLoading: false,
        totalGames: list.length,
        wins: wins,
        losses: losses,
        draws: draws,
      );
    } on DioException {
      // Offline demo data
      final mock = _mockHistory();
      state = state.copyWith(
        history: mock,
        isLoading: false,
        totalGames: mock.length,
        wins: mock.where((h) => h.result == 'win').length,
        losses: mock.where((h) => h.result == 'loss').length,
        draws: mock.where((h) => h.result == 'draw').length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<GameHistory> _mockHistory() => [
        GameHistory(
          id: 'h1',
          gameId: 'g1',
          gameTitle: 'Weekend Football',
          category: 'offline',
          result: 'win',
          score: 3,
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        GameHistory(
          id: 'h2',
          gameId: 'g2',
          gameTitle: 'Chess Tournament',
          category: 'online',
          result: 'loss',
          score: 0,
          date: DateTime.now().subtract(const Duration(days: 4)),
        ),
        GameHistory(
          id: 'h3',
          gameId: 'g3',
          gameTitle: 'Basketball 3v3',
          category: 'offline',
          result: 'draw',
          score: 21,
          date: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
}

// ── Provider ──────────────────────────────────────────────────────────────────

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HistoryNotifier(apiClient);
});

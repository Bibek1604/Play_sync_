import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/scorecard/domain/entities/scorecard.dart';
import 'package:play_sync_new/features/scorecard/domain/entities/points_trend.dart';
import 'package:play_sync_new/features/scorecard/presentation/providers/scorecard_providers.dart';

/// Scorecard State
class ScorecardState {
  final Scorecard? scorecard;
  final List<PointsTrend> trendData;
  final bool isLoading;
  final bool isLoadingTrend;
  final String? error;
  final String trendPeriod; // 'week', 'month', 'year'

  ScorecardState({
    this.scorecard,
    this.trendData = const [],
    this.isLoading = false,
    this.isLoadingTrend = false,
    this.error,
    this.trendPeriod = 'month',
  });

  ScorecardState copyWith({
    Scorecard? scorecard,
    List<PointsTrend>? trendData,
    bool? isLoading,
    bool? isLoadingTrend,
    String? error,
    String? trendPeriod,
  }) {
    return ScorecardState(
      scorecard: scorecard ?? this.scorecard,
      trendData: trendData ?? this.trendData,
      isLoading: isLoading ?? this.isLoading,
      isLoadingTrend: isLoadingTrend ?? this.isLoadingTrend,
      error: error,
      trendPeriod: trendPeriod ?? this.trendPeriod,
    );
  }

  /// Check if scorecard has data
  bool get hasData => scorecard != null;

  /// Check if trend has data
  bool get hasTrendData => trendData.isNotEmpty;
}

/// Scorecard Notifier
class ScorecardNotifier extends StateNotifier<ScorecardState> {
  final Ref ref;

  ScorecardNotifier(this.ref) : super(ScorecardState());

  /// Load scorecard
  Future<void> loadScorecard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final getScorecard = ref.read(getScorecardUseCaseProvider);
      final scorecard = await getScorecard();

      state = state.copyWith(
        scorecard: scorecard,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load trend data
  Future<void> loadTrend({String period = 'month'}) async {
    state = state.copyWith(
      isLoadingTrend: true,
      trendPeriod: period,
    );

    try {
      final getTrend = ref.read(getTrendUseCaseProvider);
      
      int days = 30;
      if (period == 'week') days = 7;
      if (period == 'year') days = 365;
      
      final trendData = await getTrend(days: days);

      state = state.copyWith(
        trendData: trendData,
        isLoadingTrend: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTrend: false,
        error: e.toString(),
      );
    }
  }

  /// Load all data
  Future<void> loadAll({String trendPeriod = 'month'}) async {
    await Future.wait([
      loadScorecard(),
      loadTrend(period: trendPeriod),
    ]);
  }

  /// Refresh scorecard
  Future<void> refresh() async {
    await loadAll(trendPeriod: state.trendPeriod);
  }

  /// Change trend period
  Future<void> changeTrendPeriod(String period) async {
    if (period != state.trendPeriod) {
      await loadTrend(period: period);
    }
  }
}

/// Scorecard State Provider
final scorecardProvider = StateNotifierProvider<ScorecardNotifier, ScorecardState>((ref) {
  return ScorecardNotifier(ref);
});

/// Performance metrics provider
final performanceMetricsProvider = Provider<Map<String, dynamic>?>((ref) {
  final scorecard = ref.watch(scorecardProvider.select((state) => state.scorecard));
  if (scorecard == null) return null;

  return {
    'winRate': scorecard.winRate,
    'totalGames': scorecard.totalGames,
    'wins': scorecard.wins,
    'losses': scorecard.losses,
    'averageScore': scorecard.averageScore,
  };
});

/// Trend chart data provider
final trendChartDataProvider = Provider<List<PointsTrend>>((ref) {
  return ref.watch(scorecardProvider.select((state) => state.trendData));
});

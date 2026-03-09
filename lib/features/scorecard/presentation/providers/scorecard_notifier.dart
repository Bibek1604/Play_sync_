import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scorecard_entity.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
class ScorecardState {
  final ScorecardEntity? scorecard;
  final bool isLoading;
  final String? error;

  const ScorecardState({this.scorecard, this.isLoading = false, this.error});

  ScorecardState copyWith({
    ScorecardEntity? scorecard,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ScorecardState(
        scorecard: scorecard ?? this.scorecard,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}
class ScorecardNotifier extends StateNotifier<ScorecardState> {
  final ApiClient _api;
  ScorecardNotifier(this._api) : super(const ScorecardState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resp = await _api.get(ApiEndpoints.getMyScorecard);
      final sc = ScorecardEntity.fromJson(resp.data as Map<String, dynamic>);
      state = state.copyWith(scorecard: sc, isLoading: false);
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 401
          ? 'Session expired. Please login again.'
          : (e.response?.data is Map
              ? (e.response!.data['message'] ?? 'Failed to load scorecard')
              : 'Failed to load scorecard');
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
final scorecardProvider =
    StateNotifierProvider<ScorecardNotifier, ScorecardState>((ref) {
  final api = ref.watch(apiClientProvider);
  return ScorecardNotifier(api);
});

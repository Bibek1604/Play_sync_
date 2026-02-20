import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

// ── Entity ────────────────────────────────────────────────────────────────────

class ScoreBreakdown {
  final String category;
  final int points;

  const ScoreBreakdown({required this.category, required this.points});

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      category: json['category'] as String? ?? '',
      points: json['points'] as int? ?? 0,
    );
  }
}

class Scorecard {
  final String id;
  final String gameId;
  final String gameTitle;
  final int totalScore;
  final List<ScoreBreakdown> breakdown;
  final DateTime createdAt;

  const Scorecard({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.totalScore,
    required this.breakdown,
    required this.createdAt,
  });

  factory Scorecard.fromJson(Map<String, dynamic> json) {
    return Scorecard(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      gameId: json['gameId'] as String? ?? '',
      gameTitle: json['gameTitle'] as String? ?? 'Unknown',
      totalScore: json['totalScore'] as int? ?? 0,
      breakdown:
          (json['breakdown'] as List? ?? [])
              .map((j) =>
                  ScoreBreakdown.fromJson(j as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

class ScorecardState {
  final List<Scorecard> scorecards;
  final bool isLoading;
  final String? error;

  const ScorecardState(
      {this.scorecards = const [], this.isLoading = false, this.error});

  ScorecardState copyWith(
      {List<Scorecard>? scorecards, bool? isLoading, String? error}) {
    return ScorecardState(
      scorecards: scorecards ?? this.scorecards,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ScorecardNotifier extends StateNotifier<ScorecardState> {
  final ApiClient _apiClient;
  ScorecardNotifier(this._apiClient) : super(const ScorecardState()) {
    fetchScorecards();
  }

  Future<void> fetchScorecards() async {
    state = state.copyWith(isLoading: true);
    try {
      final resp = await _apiClient.get('/scorecards');
      final data = resp.data as Map<String, dynamic>;
      final list = (data['scorecards'] as List? ?? [])
          .map((j) => Scorecard.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(scorecards: list, isLoading: false);
    } on DioException {
      // Offline mock
      state = state.copyWith(
        scorecards: _mockScorecards(),
        isLoading: false,
      );
    }
  }

  List<Scorecard> _mockScorecards() => [
        Scorecard(
          id: 's1',
          gameId: 'g1',
          gameTitle: 'Weekend Football',
          totalScore: 120,
          breakdown: const [
            ScoreBreakdown(category: 'Goals', points: 60),
            ScoreBreakdown(category: 'Assists', points: 40),
            ScoreBreakdown(category: 'Defense', points: 20),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}

final scorecardProvider =
    StateNotifierProvider<ScorecardNotifier, ScorecardState>((ref) {
  return ScorecardNotifier(ref.watch(apiClientProvider));
});

// ── Page ──────────────────────────────────────────────────────────────────────

class ScorecardPage extends ConsumerWidget {
  const ScorecardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scorecardProvider);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(scorecardProvider.notifier).fetchScorecards(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.scorecards.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.score, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No scorecards found'),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.scorecards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final sc = state.scorecards[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(sc.gameTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('${sc.totalScore} pts',
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(dateFmt.format(sc.createdAt),
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.6))),
                            const Divider(height: 20),
                            ...sc.breakdown.map((b) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(b.category),
                                      Text('${b.points} pts',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

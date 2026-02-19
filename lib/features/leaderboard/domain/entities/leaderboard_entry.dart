import 'package:freezed_annotation/freezed_annotation.dart';

part 'leaderboard_entry.freezed.dart';
part 'leaderboard_entry.g.dart';

/// A single row in the leaderboard.
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String userId,
    required String username,
    String? profileImageUrl,
    required int rank,
    required int totalPoints,
    required int gamesPlayed,
    required int gamesWon,
    required double winRate,
    @Default(0) int currentStreak,
    @Default(false) bool isCurrentUser,
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

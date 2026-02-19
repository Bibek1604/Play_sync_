import 'package:equatable/equatable.dart';

/// Aggregated statistics for a user's activity on PlaySync.
class ProfileStats extends Equatable {
  final int totalGamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final double winRate;
  final String? mostPlayedGame;
  final DateTime? lastActive;

  const ProfileStats({
    required this.totalGamesPlayed,
    required this.gamesWon,
    required this.gamesLost,
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.winRate,
    this.mostPlayedGame,
    this.lastActive,
  });

  /// Returns a completion percentage (0–100) based on filled fields.
  int get completionPercent {
    int filled = 0;
    if (totalGamesPlayed > 0) filled++;
    if (gamesWon > 0) filled++;
    if (totalPoints > 0) filled++;
    if (mostPlayedGame != null) filled++;
    if (lastActive != null) filled++;
    return (filled / 5 * 100).round();
  }

  const ProfileStats.empty()
      : totalGamesPlayed = 0,
        gamesWon = 0,
        gamesLost = 0,
        totalPoints = 0,
        currentStreak = 0,
        longestStreak = 0,
        winRate = 0.0,
        mostPlayedGame = null,
        lastActive = null;

  @override
  List<Object?> get props => [
        totalGamesPlayed,
        gamesWon,
        gamesLost,
        totalPoints,
        currentStreak,
        longestStreak,
        winRate,
        mostPlayedGame,
        lastActive,
      ];
}

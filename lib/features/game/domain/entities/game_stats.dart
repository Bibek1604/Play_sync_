import 'package:equatable/equatable.dart';

/// Aggregated statistics for a single game session.
class GameStats extends Equatable {
  final String gameId;
  final int totalMessages;
  final int peakPlayers;
  final Duration gameDuration;
  final String? winnerUserId;
  final Map<String, int> playerScores;

  const GameStats({
    required this.gameId,
    required this.totalMessages,
    required this.peakPlayers,
    required this.gameDuration,
    this.winnerUserId,
    this.playerScores = const {},
  });

  int? scoreOf(String userId) => playerScores[userId];

  bool get hasWinner => winnerUserId != null;

  const GameStats.empty(String id)
      : gameId = id,
        totalMessages = 0,
        peakPlayers = 0,
        gameDuration = Duration.zero,
        winnerUserId = null,
        playerScores = const {};

  @override
  List<Object?> get props =>
      [gameId, totalMessages, peakPlayers, gameDuration, winnerUserId];
}

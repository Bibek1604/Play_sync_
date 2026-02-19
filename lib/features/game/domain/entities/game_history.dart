/// Game History Entity (Domain Layer)
class GameHistory {
  final String id;
  final String gameName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int playersCount;
  final int? finalScore;
  final String? winnerId;
  final String? winnerName;
  final String status;

  const GameHistory({
    required this.id,
    required this.gameName,
    required this.startedAt,
    this.endedAt,
    required this.playersCount,
    this.finalScore,
    this.winnerId,
    this.winnerName,
    required this.status,
  });

  Duration? get duration => endedAt != null
      ? endedAt!.difference(startedAt)
      : null;

  bool get isCompleted => endedAt != null;

  GameHistory copyWith({
    String? id,
    String? gameName,
    DateTime? startedAt,
    DateTime? endedAt,
    int? playersCount,
    int? finalScore,
    String? winnerId,
    String? winnerName,
    String? status,
  }) {
    return GameHistory(
      id: id ?? this.id,
      gameName: gameName ?? this.gameName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      playersCount: playersCount ?? this.playersCount,
      finalScore: finalScore ?? this.finalScore,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      status: status ?? this.status,
    );
  }
}

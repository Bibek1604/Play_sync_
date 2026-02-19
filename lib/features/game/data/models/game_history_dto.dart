import 'package:play_sync_new/features/game/domain/entities/game_history.dart';

/// Game History DTO
class GameHistoryDto {
  final String id;
  final String gameName;
  final String startedAt;
  final String? endedAt;
  final int playersCount;
  final int? finalScore;
  final String? winnerId;
  final String? winnerName;
  final String status;

  GameHistoryDto({
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

  factory GameHistoryDto.fromJson(Map<String, dynamic> json) {
    return GameHistoryDto(
      id: json['id'] ?? json['_id'] ?? '',
      gameName: json['gameName'] ?? json['game_name'] ?? '',
      startedAt: json['startedAt'] ?? json['started_at'] ?? DateTime.now().toIso8601String(),
      endedAt: json['endedAt'] ?? json['ended_at'],
      playersCount: json['playersCount'] ?? json['players_count'] ?? 0,
      finalScore: json['finalScore'] ?? json['final_score'],
      winnerId: json['winnerId'] ?? json['winner_id'],
      winnerName: json['winnerName'] ?? json['winner_name'],
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameName': gameName,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'playersCount': playersCount,
      'finalScore': finalScore,
      'winnerId': winnerId,
      'winnerName': winnerName,
      'status': status,
    };
  }

  GameHistory toEntity() {
    return GameHistory(
      id: id,
      gameName: gameName,
      startedAt: DateTime.parse(startedAt),
      endedAt: endedAt != null ? DateTime.parse(endedAt!) : null,
      playersCount: playersCount,
      finalScore: finalScore,
      winnerId: winnerId,
      winnerName: winnerName,
      status: status,
    );
  }
}

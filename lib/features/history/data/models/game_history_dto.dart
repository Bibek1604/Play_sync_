import 'package:play_sync_new/features/game/data/models/game_dto.dart';
import 'package:play_sync_new/features/history/domain/entities/game_history.dart';

class GameHistoryDto {
  final String id;
  final GameDto game;
  final String userId;
  final String joinedAt;
  final String? leftAt;
  final String? completedAt;
  final int pointsEarned;
  final bool leftEarly;
  final String status;

  GameHistoryDto({
    required this.id,
    required this.game,
    required this.userId,
    required this.joinedAt,
    this.leftAt,
    this.completedAt,
    required this.pointsEarned,
    required this.leftEarly,
    required this.status,
  });

  /// Parse from backend response.
  ///
  /// The backend returns entries with this shape (as of refactor):
  /// ```json
  /// {
  ///   "gameId": "...", "title": "...", "category": "ONLINE", "status": "OPEN",
  ///   "myParticipation": { "joinedAt": "...", "leftAt": null,
  ///                        "participationStatus": "ACTIVE", "durationMinutes": null },
  ///   "gameInfo": { "creatorName": "...", "maxPlayers": 10, "currentPlayers": 5,
  ///                 "endTime": "...", "imageUrl": "..." }
  /// }
  /// ```
  ///
  /// Older Hive-cached entries may still use the legacy structure with a nested
  /// `game` object — both formats are handled here.
  factory GameHistoryDto.fromJson(Map<String, dynamic> json) {
    // ── NEW backend format (has 'myParticipation') ──
    if (json.containsKey('myParticipation')) {
      final p = (json['myParticipation'] as Map<String, dynamic>?) ?? {};
      final g = (json['gameInfo'] as Map<String, dynamic>?) ?? {};

      final gameId = json['gameId']?.toString() ?? json['_id']?.toString() ?? '';
      final participationStatus = p['participationStatus']?.toString() ?? 'ACTIVE';
      final leftEarly = participationStatus == 'LEFT';

      // Derive a readable status: ENDED/CANCELLED games are "completed"/"cancelled",
      // LEFT participation = user left early, otherwise treat as "active"
      final gameStatus = json['status']?.toString() ?? 'OPEN';
      final String derivedStatus;
      if (gameStatus == 'ENDED' || gameStatus == 'CANCELLED') {
        derivedStatus = gameStatus.toLowerCase();
      } else if (leftEarly) {
        derivedStatus = 'left';
      } else {
        derivedStatus = 'active';
      }

      // Build a synthetic GameDto from the flattened gameInfo fields so the
      // existing GameHistory entity (and history UI) keep working unchanged.
      final syntheticGame = GameDto.fromJson({
        '_id': gameId,
        'title': json['title'] ?? '',
        'category': json['category'] ?? 'ONLINE',
        'status': gameStatus,
        'imageUrl': g['imageUrl'],
        'maxPlayers': g['maxPlayers'] ?? 2,
        'minPlayers': 2,
        'currentPlayers': g['currentPlayers'] ?? 0,
        'creatorId': '',
        'participants': <dynamic>[],
        'tags': <dynamic>[],
        'startTime': p['joinedAt'],
        'endTime': g['endTime'],
        'createdAt': p['joinedAt'],
        'updatedAt': p['joinedAt'],
      });

      return GameHistoryDto(
        id: gameId,
        game: syntheticGame,
        userId: '',
        joinedAt: p['joinedAt']?.toString() ?? DateTime.now().toIso8601String(),
        leftAt: p['leftAt']?.toString(),
        completedAt: null,
        pointsEarned: 0,
        leftEarly: leftEarly,
        status: derivedStatus,
      );
    }

    // ── LEGACY / Hive-cached format (has nested 'game' object) ──
    final historyId = json['_id'] ?? json['id'] ?? '';
    return GameHistoryDto(
      id: historyId,
      game: GameDto.fromJson((json['game'] as Map<String, dynamic>?) ?? {}),
      userId: json['userId'] ?? json['user_id'] ?? '',
      joinedAt: json['joinedAt'] ?? json['joined_at'] ?? DateTime.now().toIso8601String(),
      leftAt: json['leftAt'] ?? json['left_at'],
      completedAt: json['completedAt'] ?? json['completed_at'],
      pointsEarned: json['pointsEarned'] ?? json['points_earned'] ?? 0,
      leftEarly: json['leftEarly'] ?? json['left_early'] ?? false,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'game': game.toJson(),
      'userId': userId,
      'joinedAt': joinedAt,
      'leftAt': leftAt,
      'completedAt': completedAt,
      'pointsEarned': pointsEarned,
      'leftEarly': leftEarly,
      'status': status,
    };
  }

  GameHistory toEntity() {
    return GameHistory(
      id: id,
      game: game.toEntity(),
      userId: userId,
      joinedAt: DateTime.parse(joinedAt),
      leftAt: leftAt != null ? DateTime.parse(leftAt!) : null,
      completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
      pointsEarned: pointsEarned,
      leftEarly: leftEarly,
      status: status,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Participation details for a game history entry.
class ParticipationDetails {
  final DateTime? joinedAt;
  final DateTime? leftAt;
  final String participationStatus; // 'ACTIVE' | 'LEFT'
  final int? durationMinutes;

  const ParticipationDetails({
    this.joinedAt,
    this.leftAt,
    this.participationStatus = 'ACTIVE',
    this.durationMinutes,
  });

  factory ParticipationDetails.fromJson(Map<String, dynamic> json) {
    return ParticipationDetails(
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? ''),
      leftAt: json['leftAt'] != null ? DateTime.tryParse(json['leftAt'] as String) : null,
      participationStatus: json['participationStatus'] as String? ?? 'ACTIVE',
      durationMinutes: json['durationMinutes'] as int?,
    );
  }
}

/// Basic game info for history entry.
class GameBasicInfo {
  final String creatorName;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime? endTime;
  final String? imageUrl;

  const GameBasicInfo({
    this.creatorName = 'Unknown',
    this.maxPlayers = 0,
    this.currentPlayers = 0,
    this.endTime,
    this.imageUrl,
  });

  factory GameBasicInfo.fromJson(Map<String, dynamic> json) {
    return GameBasicInfo(
      creatorName: json['creatorName'] as String? ?? 'Unknown',
      maxPlayers: json['maxPlayers'] as int? ?? 0,
      currentPlayers: json['currentPlayers'] as int? ?? 0,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// Represents a single entry in the user's game history.
/// Matches backend GameHistoryEntry type.
class GameHistory extends Equatable {
  final String gameId;
  final String title;
  /// 'ONLINE' or 'OFFLINE'
  final String category;
  /// 'OPEN', 'FULL', 'ENDED', 'CANCELLED'
  final String status;
  final ParticipationDetails myParticipation;
  final GameBasicInfo gameInfo;

  const GameHistory({
    required this.gameId,
    required this.title,
    required this.category,
    required this.status,
    required this.myParticipation,
    required this.gameInfo,
  });

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      gameId: json['gameId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Game',
      category: json['category'] as String? ?? 'OFFLINE',
      status: json['status'] as String? ?? 'OPEN',
      myParticipation: ParticipationDetails.fromJson(
        (json['myParticipation'] as Map<String, dynamic>?) ?? {},
      ),
      gameInfo: GameBasicInfo.fromJson(
        (json['gameInfo'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  /// Status icon
  String get statusIcon => switch (status) {
    'ENDED' => '✅',
    'CANCELLED' => '❌',
    'OPEN' => '🟢',
    'FULL' => '🟡',
    _ => '🎮',
  };

  /// Participation status indicator
  bool get isActive => myParticipation.participationStatus == 'ACTIVE';

  @override
  List<Object?> get props => [gameId, status, category];
}

import 'package:play_sync_new/features/game/domain/entities/game.dart';

class GameHistory {
  final String id;
  final Game game;
  final String userId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? completedAt;
  final int pointsEarned;
  final bool leftEarly;
  final String status; // 'completed', 'cancelled', 'active'

  GameHistory({
    required this.id,
    required this.game,
    required this.userId,
    required this.joinedAt,
    this.leftAt,
    this.completedAt,
    this.pointsEarned = 0,
    this.leftEarly = false,
    this.status = 'active',
  });

  // Business logic
  Duration? get duration {
    if (leftAt != null) {
      return leftAt!.difference(joinedAt);
    }
    if (completedAt != null) {
      return completedAt!.difference(joinedAt);
    }
    return null;
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'In Progress';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

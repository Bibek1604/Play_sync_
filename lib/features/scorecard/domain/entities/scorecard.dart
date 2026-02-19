class Scorecard {
  final String? userId;
  final int points;
  final int totalPoints;
  final int rank;
  final int gamesJoined;
  final int gamesPlayed;
  final int totalMinutesPlayed;
  final DateTime? updatedAt;
  final PointsBreakdown? breakdown;

  Scorecard({
    this.userId,
    required this.points,
    int? totalPoints,
    required this.rank,
    int? gamesJoined,
    int? gamesPlayed,
    int? totalMinutesPlayed,
    this.updatedAt,
    this.breakdown,
  })  : totalPoints = totalPoints ?? points,
        gamesJoined = gamesJoined ?? 0,
        gamesPlayed = gamesPlayed ?? 0,
        totalMinutesPlayed = totalMinutesPlayed ?? 0;

  // Business logic
  double get averagePointsPerGame {
    if (gamesPlayed == 0) return 0.0;
    return points / gamesPlayed;
  }

  int get totalGames => gamesPlayed;
  double get averageScore => averagePointsPerGame;
  
  // Placeholder values for stats not yet available from backend
  int get wins => 0;
  int get losses => 0;
  double get winRate => 0.0;

  String get formattedPlayTime {
    if (totalMinutesPlayed < 60) {
      return '$totalMinutesPlayed mins';
    }
    final hours = (totalMinutesPlayed / 60).floor();
    final minutes = totalMinutesPlayed % 60;
    return '${hours}h ${minutes}m';
  }

  bool get hasBreakdown => breakdown != null;
}

class PointsBreakdown {
  final int pointsFromJoins;
  final int pointsFromTime;

  PointsBreakdown({
    required this.pointsFromJoins,
    required this.pointsFromTime,
  });

  int get total => pointsFromJoins + pointsFromTime;
}

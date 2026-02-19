import 'package:play_sync_new/features/scorecard/domain/entities/scorecard.dart';

class ScorecardDto {
  final String? userId;
  final int points;
  final int? totalPoints;
  final int rank;
  final int? gamesJoined;
  final int? gamesPlayed;
  final int? totalMinutesPlayed;
  final String? updatedAt;
  final BreakdownDto? breakdown;

  ScorecardDto({
    this.userId,
    required this.points,
    this.totalPoints,
    required this.rank,
    this.gamesJoined,
    this.gamesPlayed,
    this.totalMinutesPlayed,
    this.updatedAt,
    this.breakdown,
  });

  factory ScorecardDto.fromJson(Map<String, dynamic> json) {
    // Backend sends 'totalPoints' (not 'points') for the scorecard endpoint.
    // Read totalPoints first; fall back to 'points' for any cached/legacy data.
    final totalPts = json['totalPoints'] ?? json['total_points'] ?? json['points'] ?? 0;
    return ScorecardDto(
      userId: json['userId'] ?? json['user_id'],
      points: totalPts,
      totalPoints: totalPts,
      rank: json['rank'] ?? 0,
      gamesJoined: json['gamesJoined'] ?? json['games_joined'],
      gamesPlayed: json['gamesPlayed'] ?? json['games_played'],
      totalMinutesPlayed: json['totalMinutesPlayed'] ?? json['total_minutes_played'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      breakdown: json['breakdown'] != null 
          ? BreakdownDto.fromJson(json['breakdown'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'points': points,
      'totalPoints': totalPoints,
      'rank': rank,
      'gamesJoined': gamesJoined,
      'gamesPlayed': gamesPlayed,
      'totalMinutesPlayed': totalMinutesPlayed,
      'updatedAt': updatedAt,
      'breakdown': breakdown?.toJson(),
    };
  }

  Scorecard toEntity() {
    return Scorecard(
      userId: userId,
      points: points,
      totalPoints: totalPoints,
      rank: rank,
      gamesJoined: gamesJoined,
      gamesPlayed: gamesPlayed,
      totalMinutesPlayed: totalMinutesPlayed,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
      breakdown: breakdown?.toEntity(),
    );
  }
}

class BreakdownDto {
  final int pointsFromJoins;
  final int pointsFromTime;

  BreakdownDto({
    required this.pointsFromJoins,
    required this.pointsFromTime,
  });

  factory BreakdownDto.fromJson(Map<String, dynamic> json) {
    return BreakdownDto(
      pointsFromJoins: json['pointsFromJoins'] ?? json['points_from_joins'] ?? 0,
      pointsFromTime: json['pointsFromTime'] ?? json['points_from_time'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointsFromJoins': pointsFromJoins,
      'pointsFromTime': pointsFromTime,
    };
  }

  PointsBreakdown toEntity() {
    return PointsBreakdown(
      pointsFromJoins: pointsFromJoins,
      pointsFromTime: pointsFromTime,
    );
  }
}

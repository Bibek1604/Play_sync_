import 'package:play_sync_new/features/history/domain/entities/participation_stats.dart';

class ParticipationStatsDto {
  final int totalGames;
  final int completedGames;
  final int cancelledGames;
  final int activeGames;
  final int leftEarly;
  final double? winRate;

  ParticipationStatsDto({
    required this.totalGames,
    required this.completedGames,
    required this.cancelledGames,
    required this.activeGames,
    required this.leftEarly,
    this.winRate,
  });

  factory ParticipationStatsDto.fromJson(Map<String, dynamic> json) {
    return ParticipationStatsDto(
      totalGames: json['totalGames'] ?? json['total_games'] ?? 0,
      completedGames: json['completedGames'] ?? json['completed_games'] ?? 0,
      cancelledGames: json['cancelledGames'] ?? json['cancelled_games'] ?? 0,
      activeGames: json['activeGames'] ?? json['active_games'] ?? 0,
      leftEarly: json['leftEarly'] ?? json['left_early'] ?? 0,
      winRate: json['winRate']?.toDouble() ?? json['win_rate']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGames': totalGames,
      'completedGames': completedGames,
      'cancelledGames': cancelledGames,
      'activeGames': activeGames,
      'leftEarly': leftEarly,
      'winRate': winRate,
    };
  }

  ParticipationStats toEntity() {
    return ParticipationStats(
      totalGames: totalGames,
      completedGames: completedGames,
      cancelledGames: cancelledGames,
      activeGames: activeGames,
      leftEarly: leftEarly,
      winRate: winRate,
    );
  }
}

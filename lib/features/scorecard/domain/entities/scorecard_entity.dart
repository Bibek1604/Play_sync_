import 'package:equatable/equatable.dart';

/// Scorecard data returned by GET /users/me/scorecard
class ScorecardEntity extends Equatable {
  final String userId;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final double xpProgress;   // 0.0 – 1.0
  final int wins;
  final int losses;
  final int totalGames;
  final double winRate;       // 0.0 – 1.0
  final int rank;

  const ScorecardEntity({
    required this.userId,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.xpProgress,
    required this.wins,
    required this.losses,
    required this.totalGames,
    required this.winRate,
    required this.rank,
  });

  int get draws => totalGames - wins - losses;
  String get winRateLabel => '${(winRate * 100).toStringAsFixed(1)}%';
  String get xpProgressLabel => '$xp / $xpToNextLevel XP';

  factory ScorecardEntity.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    // Backend sends 'gamesPlayed' not 'totalGames'
    final total   = data['totalGames'] as int? ?? data['gamesPlayed'] as int? ?? 0;
    final wins    = data['wins'] as int? ?? 0;
    final losses  = data['losses'] as int? ?? 0;
    final xp      = data['xp'] as int? ?? 0;
    final level   = data['level'] as int? ?? 1;
    // Backend doesn't send xpToNextLevel; compute from level (1000 XP per level)
    final nextXP  = data['xpToNextLevel'] as int? ?? (level * 1000);

    return ScorecardEntity(
      userId:       data['userId'] as String? ?? '',
      level:        level,
      xp:           xp,
      xpToNextLevel: nextXP,
      xpProgress:   nextXP > 0 ? (xp / nextXP).clamp(0.0, 1.0) : 0,
      wins:         wins,
      losses:       losses,
      totalGames:   total,
      winRate:      total > 0 ? (wins / total) : 0,
      rank:         data['rank']   as int? ?? 0,
    );
  }

  factory ScorecardEntity.empty() => const ScorecardEntity(
        userId: '',
        level: 1,
        xp: 0,
        xpToNextLevel: 1000,
        xpProgress: 0,
        wins: 0,
        losses: 0,
        totalGames: 0,
        winRate: 0,
        rank: 0,
      );

  @override
  List<Object?> get props =>
      [userId, level, xp, wins, losses, totalGames, rank];
}

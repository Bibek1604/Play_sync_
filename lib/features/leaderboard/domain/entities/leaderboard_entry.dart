import 'package:equatable/equatable.dart';

/// A single row in the leaderboard — matches backend LeaderboardEntry type.
///
/// Backend fields: rank, userId, fullName, avatar, xp, level, wins, totalGames
class LeaderboardEntry extends Equatable {
  final String userId;
  final String fullName;
  final String? avatar;
  final int rank;
  final int xp;
  final int level;
  final int wins;
  final int totalGames;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    this.avatar,
    required this.rank,
    required this.xp,
    required this.level,
    required this.wins,
    required this.totalGames,
    this.isCurrentUser = false,
  });

  /// Computed win rate (0.0 – 1.0)
  double get winRate => totalGames > 0 ? wins / totalGames : 0;

  /// Initials for avatar fallback
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? fullName,
    String? avatar,
    int? rank,
    int? xp,
    int? level,
    int? wins,
    int? totalGames,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      rank: rank ?? this.rank,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      wins: wins ?? this.wins,
      totalGames: totalGames ?? this.totalGames,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Unknown',
      avatar: json['avatar'] as String?,
      rank: json['rank'] as int? ?? 0,
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      wins: json['wins'] as int? ?? 0,
      totalGames: json['totalGames'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'avatar': avatar,
        'rank': rank,
        'xp': xp,
        'level': level,
        'wins': wins,
        'totalGames': totalGames,
      };

  @override
  List<Object?> get props => [userId, rank, xp, isCurrentUser];
}

import 'package:equatable/equatable.dart';

/// A single row in the leaderboard.
class LeaderboardEntry extends Equatable {
  final String userId;
  final String username;
  final String? profileImageUrl;
  final int rank;
  final int totalPoints;
  final int gamesPlayed;
  final int gamesWon;
  final double winRate;
  final int currentStreak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.rank,
    required this.totalPoints,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.winRate,
    this.currentStreak = 0,
    this.isCurrentUser = false,
  });

  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? profileImageUrl,
    int? rank,
    int? totalPoints,
    int? gamesPlayed,
    int? gamesWon,
    double? winRate,
    int? currentStreak,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rank: rank ?? this.rank,
      totalPoints: totalPoints ?? this.totalPoints,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      winRate: winRate ?? this.winRate,
      currentStreak: currentStreak ?? this.currentStreak,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      rank: json['rank'] as int,
      totalPoints: json['totalPoints'] as int,
      gamesPlayed: json['gamesPlayed'] as int,
      gamesWon: json['gamesWon'] as int,
      winRate: (json['winRate'] as num).toDouble(),
      currentStreak: json['currentStreak'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'rank': rank,
        'totalPoints': totalPoints,
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'winRate': winRate,
        'currentStreak': currentStreak,
        'isCurrentUser': isCurrentUser,
      };

  @override
  List<Object?> get props => [userId, rank, totalPoints, isCurrentUser];
}

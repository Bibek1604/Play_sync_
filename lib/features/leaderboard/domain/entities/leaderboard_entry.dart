class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int points;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.points,
    required this.rank,
  });

  // Business logic
  bool get isTopThree => rank <= 3;
  
  String get rankDisplay {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}

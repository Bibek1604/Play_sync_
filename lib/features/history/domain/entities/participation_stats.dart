class ParticipationStats {
  final int totalGames;
  final int completedGames;
  final int cancelledGames;
  final int activeGames;
  final int leftEarly;
  final double? winRate;

  ParticipationStats({
    required this.totalGames,
    required this.completedGames,
    required this.cancelledGames,
    required this.activeGames,
    required this.leftEarly,
    this.winRate,
  });

  // Business logic
  double get completionRate {
    if (totalGames == 0) return 0.0;
    return (completedGames / totalGames) * 100;
  }

  double get cancellationRate {
    if (totalGames == 0) return 0.0;
    return (cancelledGames / totalGames) * 100;
  }

  double get earlyLeaveRate {
    if (totalGames == 0) return 0.0;
    return (leftEarly / totalGames) * 100;
  }

  bool get hasGoodStats => completionRate >= 70 && earlyLeaveRate <= 20;
}

import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_stats.dart';
import 'package:play_sync_new/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class GetLeaderboardStats {
  final LeaderboardRepository repository;

  GetLeaderboardStats(this.repository);

  Future<LeaderboardStats> call() async {
    return await repository.getStats();
  }
}

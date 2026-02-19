import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_stats.dart';

abstract class LeaderboardRepository {
  /// Get leaderboard with optional filters
  Future<List<LeaderboardEntry>> getLeaderboard({
    int page = 1,
    int limit = 50,
    String period = 'all', // 'daily', 'weekly', 'monthly', 'all'
  });

  /// Get leaderboard statistics
  Future<LeaderboardStats> getStats();
}

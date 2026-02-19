import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:play_sync_new/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class GetLeaderboard {
  final LeaderboardRepository repository;

  GetLeaderboard(this.repository);

  Future<List<LeaderboardEntry>> call({
    int page = 1,
    int limit = 50,
    String period = 'all',
  }) async {
    if (page < 1) {
      throw ArgumentError('Page must be at least 1');
    }

    if (limit < 1 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }

    if (!['daily', 'weekly', 'monthly', 'all'].contains(period)) {
      throw ArgumentError('Invalid period');
    }

    return await repository.getLeaderboard(
      page: page,
      limit: limit,
      period: period,
    );
  }
}

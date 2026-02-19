import 'package:play_sync_new/features/leaderboard/data/datasources/leaderboard_local_datasource.dart';
import 'package:play_sync_new/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:play_sync_new/features/leaderboard/domain/entities/leaderboard_stats.dart';
import 'package:play_sync_new/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remoteDataSource;
  final LeaderboardLocalDataSource _localDataSource;

  LeaderboardRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    int page = 1,
    int limit = 50,
    String period = 'all',
  }) async {
    // Check cache first for competitive freshness
    final cached = await _localDataSource.getCachedLeaderboard(period);
    if (cached.isNotEmpty) {
      // Return cached immediately + refresh in background
      _refreshLeaderboardCache(page: page, limit: limit, period: period);
      return cached.map((dto) => dto.toEntity()).toList();
    }

    // Fetch from remote if no cache
    final dtos = await _remoteDataSource.getLeaderboard(
      page: page,
      limit: limit,
      period: period,
    );
    
    // Cache the results
    await _localDataSource.cacheLeaderboard(period, dtos);
    
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<LeaderboardStats> getStats() async {
    // Check cache first
    final cachedStats = await _localDataSource.getCachedStats();
    if (cachedStats != null) {
      // Return cached immediately + refresh in background
      _refreshStatsCache();
      final totalPlayers = cachedStats['totalPlayers'] as int? ?? 0;
      return LeaderboardStats(totalPlayers: totalPlayers);
    }

    // Fetch from remote if no cache
    final totalPlayers = await _remoteDataSource.getStats();
    
    // Cache the stats
    await _localDataSource.cacheStats({'totalPlayers': totalPlayers});
    
    return LeaderboardStats(totalPlayers: totalPlayers);
  }

  /// Background refresh for leaderboard cache
  Future<void> _refreshLeaderboardCache({
    required int page,
    required int limit,
    required String period,
  }) async {
    try {
      final dtos = await _remoteDataSource.getLeaderboard(
        page: page,
        limit: limit,
        period: period,
      );
      await _localDataSource.cacheLeaderboard(period, dtos);
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  /// Background refresh for stats cache
  Future<void> _refreshStatsCache() async {
    try {
      final totalPlayers = await _remoteDataSource.getStats();
      await _localDataSource.cacheStats({'totalPlayers': totalPlayers});
    } catch (e) {
      // Silent fail for background refresh
    }
  }
}

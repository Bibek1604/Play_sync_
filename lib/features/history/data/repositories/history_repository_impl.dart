import 'package:play_sync_new/features/history/data/datasources/history_local_datasource.dart';
import 'package:play_sync_new/features/history/data/datasources/history_remote_datasource.dart';
import 'package:play_sync_new/features/history/domain/entities/participation_stats.dart';
import 'package:play_sync_new/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _remoteDataSource;
  final HistoryLocalDataSource _localDataSource;

  HistoryRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<HistoryListResult> getMyHistory({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    // Check cache first (for page 1 only)
    if (page == 1) {
      final cached = await _localDataSource.getCachedHistory();
      if (cached.isNotEmpty) {
        // Return cached immediately + refresh in background
        _refreshHistoryCache(page: page, limit: limit, status: status);
        
        // Note: We don't have pagination cached, so this is approximate
        return HistoryListResult(
          history: cached.map((dto) => dto.toEntity()).toList(),
          pagination: PaginationMeta(
            page: 1,
            limit: cached.length,
            total: cached.length,
            totalPages: 1,
            hasNext: false,
          ),
        );
      }
    }

    // Fetch from remote if no cache or not page 1
    final resultDto = await _remoteDataSource.getMyHistory(
      page: page,
      limit: limit,
      status: status,
    );

    // Cache the results (page 1 only)
    if (page == 1) {
      await _localDataSource.cacheHistory(resultDto.history);
    }

    return HistoryListResult(
      history: resultDto.history.map((dto) => dto.toEntity()).toList(),
      pagination: PaginationMeta(
        page: resultDto.pagination.page,
        limit: resultDto.pagination.limit,
        total: resultDto.pagination.total,
        totalPages: resultDto.pagination.totalPages,
        hasNext: resultDto.pagination.hasNext,
      ),
    );
  }

  @override
  Future<ParticipationStats> getStats() async {
    // Check cache first
    final cached = await _localDataSource.getCachedStats();
    if (cached != null) {
      // Return cached immediately + refresh in background
      _refreshStatsCache();
      return cached.toEntity();
    }

    // Fetch from remote if no cache
    final statsDto = await _remoteDataSource.getStats();
    
    // Cache the stats
    await _localDataSource.cacheStats(statsDto);
    
    return statsDto.toEntity();
  }

  @override
  Future<int> getCount() async {
    // Check cache first
    final cached = _localDataSource.getCachedCount();
    if (cached != null) {
      // Return cached immediately + refresh in background
      _refreshCountCache();
      return cached;
    }

    // Fetch from remote if no cache
    final count = await _remoteDataSource.getCount();
    
    // Cache the count
    await _localDataSource.cacheCount(count);
    
    return count;
  }

  /// Background refresh for history cache
  Future<void> _refreshHistoryCache({
    required int page,
    required int limit,
    String? status,
  }) async {
    try {
      final result = await _remoteDataSource.getMyHistory(
        page: page,
        limit: limit,
        status: status,
      );
      await _localDataSource.cacheHistory(result.history);
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  /// Background refresh for stats cache
  Future<void> _refreshStatsCache() async {
    try {
      final stats = await _remoteDataSource.getStats();
      await _localDataSource.cacheStats(stats);
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  /// Background refresh for count cache
  Future<void> _refreshCountCache() async {
    try {
      final count = await _remoteDataSource.getCount();
      await _localDataSource.cacheCount(count);
    } catch (e) {
      // Silent fail for background refresh
    }
  }
}

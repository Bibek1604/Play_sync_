import 'package:play_sync_new/features/scorecard/data/datasources/scorecard_local_datasource.dart';
import 'package:play_sync_new/features/scorecard/data/datasources/scorecard_remote_datasource.dart';
import 'package:play_sync_new/features/scorecard/domain/entities/points_trend.dart';
import 'package:play_sync_new/features/scorecard/domain/entities/scorecard.dart';
import 'package:play_sync_new/features/scorecard/domain/repositories/scorecard_repository.dart';

class ScorecardRepositoryImpl implements ScorecardRepository {
  final ScorecardRemoteDataSource _remoteDataSource;
  final ScorecardLocalDataSource _localDataSource;

  ScorecardRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<Scorecard> getMyScorecard() async {
    // Check cache first (30-minute expiration for slowly changing data)
    final cached = _localDataSource.getCachedScorecard();
    if (cached != null) {
      // Return cached immediately + refresh in background
      _refreshScorecardCache();
      return cached.toEntity();
    }

    // Fetch from remote if no cache
    final dto = await _remoteDataSource.getMyScorecard();
    
    // Cache the scorecard
    await _localDataSource.cacheScorecard(dto);
    await _localDataSource.cacheCurrentPoints(dto.points);
    await _localDataSource.cacheCurrentRank(dto.rank);
    
    return dto.toEntity();
  }

  @override
  Future<List<PointsTrend>> getTrend({int days = 7}) async {
    // Trend data is not cached due to its dynamic nature
    final dtos = await _remoteDataSource.getTrend(days: days);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  /// Background refresh for scorecard cache
  Future<void> _refreshScorecardCache() async {
    try {
      final dto = await _remoteDataSource.getMyScorecard();
      await _localDataSource.cacheScorecard(dto);
      await _localDataSource.cacheCurrentPoints(dto.points);
      await _localDataSource.cacheCurrentRank(dto.rank);
    } catch (e) {
      // Silent fail for background refresh
    }
  }
}

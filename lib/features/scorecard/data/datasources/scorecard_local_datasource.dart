import 'package:hive/hive.dart';
import 'package:play_sync_new/features/scorecard/data/models/scorecard_dto.dart';

/// Local data source for scorecard using Hive
/// Implements cache-first strategy with 30-minute expiration (slowly changing data)
class ScorecardLocalDataSource {
  final Box<dynamic> _metadataBox;
  
  static const String _scorecardKey = 'user_scorecard';
  static const String _timestampKey = 'scorecard_timestamp';
  static const String _currentPointsKey = 'current_points';
  static const String _rankKey = 'current_rank';
  static const Duration _cacheExpiration = Duration(minutes: 30); // 30 minutes

  ScorecardLocalDataSource(this._metadataBox);

  /// Cache user scorecard
  Future<void> cacheScorecard(ScorecardDto scorecard) async {
    await _metadataBox.put(_scorecardKey, scorecard.toJson());
    await _metadataBox.put(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached scorecard
  ScorecardDto? getCachedScorecard() {
    if (_isCacheExpired()) {
      return null;
    }

    final cached = _metadataBox.get(_scorecardKey);
    if (cached == null) return null;

    try {
      return ScorecardDto.fromJson(Map<String, dynamic>.from(cached));
    } catch (e) {
      return null;
    }
  }

  /// Cache current points for quick access
  Future<void> cacheCurrentPoints(int points) async {
    await _metadataBox.put(_currentPointsKey, points);
  }

  /// Get cached current points
  int? getCachedCurrentPoints() {
    return _metadataBox.get(_currentPointsKey) as int?;
  }

  /// Cache current rank
  Future<void> cacheCurrentRank(int rank) async {
    await _metadataBox.put(_rankKey, rank);
  }

  /// Get cached current rank
  int? getCachedCurrentRank() {
    return _metadataBox.get(_rankKey) as int?;
  }

  /// Update cached points after earning new points
  Future<void> updateCachedPoints(int newPoints) async {
    final cached = getCachedScorecard();
    if (cached != null) {
      final updated = ScorecardDto(
        userId: cached.userId,
        points: newPoints,
        totalPoints: cached.totalPoints,
        rank: cached.rank,
        gamesJoined: cached.gamesJoined,
        gamesPlayed: cached.gamesPlayed,
        totalMinutesPlayed: cached.totalMinutesPlayed,
        updatedAt: DateTime.now().toIso8601String(),
        breakdown: cached.breakdown,
      );
      await cacheScorecard(updated);
    }
    await cacheCurrentPoints(newPoints);
  }

  /// Check if has valid cached scorecard
  bool hasCachedScorecard() {
    return !_isCacheExpired() && _metadataBox.containsKey(_scorecardKey);
  }

  /// Check if cache is expired (30 minutes)
  bool _isCacheExpired() {
    final timestamp = _metadataBox.get(_timestampKey) as int?;
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime) > _cacheExpiration;
  }

  /// Get cache age in minutes
  int getCacheAgeMinutes() {
    final timestamp = _metadataBox.get(_timestampKey) as int?;
    if (timestamp == null) return -1;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes;
  }

  /// Clear all cached scorecard data
  Future<void> clearCache() async {
    await _metadataBox.delete(_scorecardKey);
    await _metadataBox.delete(_timestampKey);
    await _metadataBox.delete(_currentPointsKey);
    await _metadataBox.delete(_rankKey);
  }

  /// Get cache info for monitoring
  Map<String, dynamic> getCacheInfo() {
    return {
      'has_cache': hasCachedScorecard(),
      'is_expired': _isCacheExpired(),
      'age_minutes': getCacheAgeMinutes(),
      'points': getCachedCurrentPoints(),
      'rank': getCachedCurrentRank(),
    };
  }
}

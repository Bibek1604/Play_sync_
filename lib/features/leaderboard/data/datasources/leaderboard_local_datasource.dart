import 'package:hive/hive.dart';
import 'package:play_sync_new/features/leaderboard/data/models/leaderboard_entry_dto.dart';

/// Leaderboard Local Data Source (Data Layer)
/// 
/// Handles local caching of leaderboard data using Hive
class LeaderboardLocalDataSource {
  final Box<dynamic> _metadataBox;

  static const String _leaderboardPrefix = 'leaderboard_';
  static const String _statsKey = 'leaderboard_stats';

  LeaderboardLocalDataSource(this._metadataBox);

  /// Cache leaderboard by period
  Future<void> cacheLeaderboard(String period, List<LeaderboardEntryDto> entries) async {
    try {
      final key = '$_leaderboardPrefix$period';
      final jsonList = entries.map((e) => {
        'userId': {
          'id': e.userId.id,
          'fullName': e.userId.fullName,
          'avatar': e.userId.avatar,
        },
        'points': e.points,
        'rank': e.rank,
      }).toList();
      
      await _metadataBox.put(key, jsonList);
      await _updateCacheTimestamp('${key}_timestamp');
    } catch (e) {
      throw Exception('Failed to cache leaderboard: $e');
    }
  }

  /// Get cached leaderboard by period
  Future<List<LeaderboardEntryDto>> getCachedLeaderboard(String period) async {
    try {
      if (_isCacheExpired('$_leaderboardPrefix${period}_timestamp')) {
        return [];
      }
      
      final key = '$_leaderboardPrefix$period';
      final jsonList = _metadataBox.get(key) as List<dynamic>?;
      
      if (jsonList == null) return [];
      
      return jsonList.map((json) {
        final map = Map<String, dynamic>.from(json);
        return LeaderboardEntryDto.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get cached leaderboard: $e');
    }
  }

  /// Cache leaderboard stats
  Future<void> cacheStats(Map<String, dynamic> stats) async {
    try {
      await _metadataBox.put(_statsKey, stats);
      await _updateCacheTimestamp('${_statsKey}_timestamp');
    } catch (e) {
      throw Exception('Failed to cache stats: $e');
    }
  }

  /// Get cached stats
  Future<Map<String, dynamic>?> getCachedStats() async {
    try {
      if (_isCacheExpired('${_statsKey}_timestamp')) {
        return null;
      }
      
      final stats = _metadataBox.get(_statsKey);
      return stats != null ? Map<String, dynamic>.from(stats) : null;
    } catch (e) {
      throw Exception('Failed to get cached stats: $e');
    }
  }

  /// Check if leaderboard cache is valid for period
  bool hasCachedLeaderboard(String period) {
    final key = '$_leaderboardPrefix$period';
    return _metadataBox.containsKey(key) && 
           !_isCacheExpired('${key}_timestamp');
  }

  /// Clear specific period cache
  Future<void> clearPeriodCache(String period) async {
    try {
      final key = '$_leaderboardPrefix$period';
      await _metadataBox.delete(key);
      await _metadataBox.delete('${key}_timestamp');
    } catch (e) {
      throw Exception('Failed to clear period cache: $e');
    }
  }

  /// Clear all leaderboard cache
  Future<void> clearCache() async {
    try {
      final keys = _metadataBox.keys
          .where((key) => key.toString().startsWith(_leaderboardPrefix))
          .toList();
      
      for (var key in keys) {
        await _metadataBox.delete(key);
        await _metadataBox.delete('${key}_timestamp');
      }
      
      await _metadataBox.delete(_statsKey);
      await _metadataBox.delete('${_statsKey}_timestamp');
    } catch (e) {
      throw Exception('Failed to clear leaderboard cache: $e');
    }
  }

  /// Private: Update cache timestamp
  Future<void> _updateCacheTimestamp(String key) async {
    await _metadataBox.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Private: Check if cache is expired (5 minutes)
  bool _isCacheExpired(String key) {
    final timestamp = _metadataBox.get(key);
    if (timestamp == null) return true;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    // Leaderboard cache expires after 5 minutes (competitive data)
    return difference.inMinutes > 5;
  }

  /// Get cache age in minutes for period
  int? getCacheAgeMinutes(String period) {
    final key = '$_leaderboardPrefix${period}_timestamp';
    final timestamp = _metadataBox.get(key);
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes;
  }
}

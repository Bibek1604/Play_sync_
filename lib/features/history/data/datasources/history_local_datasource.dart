import 'package:hive/hive.dart';
import 'package:play_sync_new/features/history/data/models/game_history_dto.dart';
import 'package:play_sync_new/features/history/data/models/participation_stats_dto.dart';

/// History Local Data Source (Data Layer)
/// 
/// Handles local caching of game history using Hive
class HistoryLocalDataSource {
  final Box<GameHistoryDto> _historyBox;
  final Box<dynamic> _metadataBox;

  static const String _statsKey = 'participation_stats';
  static const String _countKey = 'total_count';
  static const String _historyTimestampKey = 'history_timestamp';
  static const String _statsTimestampKey = 'stats_timestamp';

  HistoryLocalDataSource(this._historyBox, this._metadataBox);

  /// Cache history list
  Future<void> cacheHistory(List<GameHistoryDto> history) async {
    try {
      final Map<String, GameHistoryDto> historyMap = {
        for (var item in history) item.id: item
      };
      await _historyBox.putAll(historyMap);
      await _updateCacheTimestamp(_historyTimestampKey);
    } catch (e) {
      throw Exception('Failed to cache history: $e');
    }
  }

  /// Get cached history
  Future<List<GameHistoryDto>> getCachedHistory() async {
    try {
      if (_isCacheExpired(_historyTimestampKey)) {
        return [];
      }
      return _historyBox.values.toList();
    } catch (e) {
      throw Exception('Failed to get cached history: $e');
    }
  }

  /// Cache participation stats
  Future<void> cacheStats(ParticipationStatsDto stats) async {
    try {
      await _metadataBox.put(_statsKey, stats.toJson());
      await _updateCacheTimestamp(_statsTimestampKey);
    } catch (e) {
      throw Exception('Failed to cache stats: $e');
    }
  }

  /// Get cached stats
  Future<ParticipationStatsDto?> getCachedStats() async {
    try {
      if (_isCacheExpired(_statsTimestampKey)) {
        return null;
      }
      final jsonData = _metadataBox.get(_statsKey);
      if (jsonData == null) return null;
      return ParticipationStatsDto.fromJson(Map<String, dynamic>.from(jsonData));
    } catch (e) {
      throw Exception('Failed to get cached stats: $e');
    }
  }

  /// Cache total count
  Future<void> cacheCount(int count) async {
    try {
      await _metadataBox.put(_countKey, count);
      await _updateCacheTimestamp(_historyTimestampKey);
    } catch (e) {
      throw Exception('Failed to cache count: $e');
    }
  }

  /// Get cached count
  int? getCachedCount() {
    if (_isCacheExpired(_historyTimestampKey)) {
      return null;
    }
    return _metadataBox.get(_countKey) as int?;
  }

  /// Check if history cache is valid
  bool hasCachedHistory() {
    return _historyBox.isNotEmpty && !_isCacheExpired(_historyTimestampKey);
  }

  /// Clear all history cache
  Future<void> clearCache() async {
    try {
      await _historyBox.clear();
      await _metadataBox.delete(_statsKey);
      await _metadataBox.delete(_countKey);
      await _metadataBox.delete(_historyTimestampKey);
      await _metadataBox.delete(_statsTimestampKey);
    } catch (e) {
      throw Exception('Failed to clear history cache: $e');
    }
  }

  /// Private: Update cache timestamp
  Future<void> _updateCacheTimestamp(String key) async {
    await _metadataBox.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Private: Check if cache is expired (10 minutes)
  bool _isCacheExpired(String key) {
    final timestamp = _metadataBox.get(key);
    if (timestamp == null) return true;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    // Cache expires after 10 minutes
    return difference.inMinutes > 10;
  }

  /// Get cache age in minutes
  int? getCacheAgeMinutes(String key) {
    final timestamp = _metadataBox.get(key);
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes;
  }
}

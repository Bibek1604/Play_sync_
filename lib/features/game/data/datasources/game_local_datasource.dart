import 'package:hive/hive.dart';
import 'package:play_sync_new/features/game/data/models/game_dto.dart';

/// Game Local Data Source (Data Layer)
/// 
/// Handles local caching of game data using Hive
class GameLocalDataSource {
  final Box<GameDto> _gamesBox;
  final Box<dynamic> _metadataBox;

  GameLocalDataSource(this._gamesBox, this._metadataBox);

  /// Save single game to local cache
  Future<void> cacheGame(GameDto game) async {
    try {
      await _gamesBox.put(game.id, game);
      await _updateCacheTimestamp('game_${game.id}');
    } catch (e) {
      throw Exception('Failed to cache game: $e');
    }
  }

  /// Save multiple games to local cache
  Future<void> cacheGames(List<GameDto> games) async {
    try {
      final Map<String, GameDto> gameMap = {
        for (var game in games) game.id: game
      };
      await _gamesBox.putAll(gameMap);
      await _updateCacheTimestamp('games_list');
    } catch (e) {
      throw Exception('Failed to cache games: $e');
    }
  }

  /// Get game by ID from local cache
  Future<GameDto?> getCachedGame(String gameId) async {
    try {
      final game = _gamesBox.get(gameId);
      if (game != null && !_isCacheExpired('game_$gameId')) {
        return game;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get cached game: $e');
    }
  }

  /// Get all cached games
  Future<List<GameDto>> getCachedGames() async {
    try {
      if (_isCacheExpired('games_list')) {
        return [];
      }
      return _gamesBox.values.toList();
    } catch (e) {
      throw Exception('Failed to get cached games: $e');
    }
  }

  /// Get games by status from cache
  Future<List<GameDto>> getCachedGamesByStatus(String status) async {
    try {
      if (_isCacheExpired('games_list')) {
        return [];
      }
      return _gamesBox.values
          .where((game) => game.status.toLowerCase() == status.toLowerCase())
          .toList();
    } catch (e) {
      throw Exception('Failed to get cached games by status: $e');
    }
  }

  /// Delete specific game from cache
  Future<void> deleteCachedGame(String gameId) async {
    try {
      await _gamesBox.delete(gameId);
      await _metadataBox.delete('game_${gameId}_timestamp');
    } catch (e) {
      throw Exception('Failed to delete cached game: $e');
    }
  }

  /// Clear all cached games
  Future<void> clearCache() async {
    try {
      await _gamesBox.clear();
      // Clear all game-related timestamps
      final keys = _metadataBox.keys
          .where((key) => key.toString().startsWith('game'))
          .toList();
      for (var key in keys) {
        await _metadataBox.delete(key);
      }
    } catch (e) {
      throw Exception('Failed to clear game cache: $e');
    }
  }

  /// Check if cache exists and is valid
  bool hasCachedGames() {
    return _gamesBox.isNotEmpty && !_isCacheExpired('games_list');
  }

  /// Update game status in cache
  Future<void> updateGameStatus(String gameId, String status) async {
    try {
      final game = _gamesBox.get(gameId);
      if (game != null) {
        final updatedGame = GameDto(
          id: game.id,
          title: game.title,
          description: game.description,
          location: game.location,
          tags: game.tags,
          imageUrl: game.imageUrl,
          imagePublicId: game.imagePublicId,
          maxPlayers: game.maxPlayers,
          minPlayers: game.minPlayers,
          currentPlayers: game.currentPlayers,
          category: game.category,
          status: status,
          creatorId: game.creatorId,
          participants: game.participants,
          startTime: game.startTime,
          endTime: game.endTime,
          endedAt: game.endedAt,
          cancelledAt: game.cancelledAt,
          completedAt: game.completedAt,
          createdAt: game.createdAt,
          updatedAt: DateTime.now(),
          metadata: game.metadata,
          latitude: game.latitude,
          longitude: game.longitude,
          maxDistance: game.maxDistance,
        );
        await _gamesBox.put(gameId, updatedGame);
      }
    } catch (e) {
      throw Exception('Failed to update game status: $e');
    }
  }

  /// Get cached games near a location
  Future<List<GameDto>> getCachedGamesNearby({
    required double latitude,
    required double longitude,
    double? maxDistanceKm,
  }) async {
    try {
      if (_isCacheExpired('games_list')) {
        return [];
      }
      
      return _gamesBox.values.where((game) {
        final entity = game.toEntity();
        return entity.isWithinDistance(latitude, longitude);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get cached games nearby: $e');
    }
  }

  /// Private: Update cache timestamp
  Future<void> _updateCacheTimestamp(String key) async {
    await _metadataBox.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Private: Check if cache is expired (5 minutes)
  bool _isCacheExpired(String key) {
    final timestamp = _metadataBox.get('${key}_timestamp');
    if (timestamp == null) return true;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);
    
    // Cache expires after 5 minutes
    return difference.inMinutes > 5;
  }

  /// Get cache age in minutes
  int? getCacheAgeMinutes(String key) {
    final timestamp = _metadataBox.get('${key}_timestamp');
    if (timestamp == null) return null;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes;
  }
}

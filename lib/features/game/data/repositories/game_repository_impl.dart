import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/features/game/domain/entities/game_history.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';
import 'package:play_sync_new/features/game/data/datasources/game_remote_datasource.dart';
import 'package:play_sync_new/features/game/data/datasources/game_local_datasource.dart';
import 'package:play_sync_new/features/game/data/datasources/chat_local_datasource.dart';

/// Game Repository Implementation (Data Layer)
/// 
/// Implements the domain repository interface with cache-first strategy
/// Coordinates between local (Hive) and remote (API) data sources
class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource _remoteDataSource;
  final GameLocalDataSource _localDataSource;
  final ChatLocalDataSource _chatLocalDataSource;

  GameRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._chatLocalDataSource,
  );

  @override
  Future<List<Game>> getAvailableGames({GameCategory? category}) async {
    // Try to get from cache first
    // Note: Caching logic might need adjustment for filtered queries
    // For simplicity, we filter the cached list if available
    if (_localDataSource.hasCachedGames()) {
      final cachedGames = await _localDataSource.getCachedGames();
      if (cachedGames.isNotEmpty) {
        var games = cachedGames.map((dto) => dto.toEntity()).toList();
        
        if (category != null) {
          games = games.where((g) => g.category == category).toList();
        }
        
        // Refresh cache in background (fetch all to keep cache complete)
        _refreshGamesCache();
        
        return games;
      }
    }
    
    // Fetch from remote if no cache
    //Ideally pass category to remote data source for server-side filtering
    // But for now, let's fetch all and filter locally or updated remote datasource
    final dtos = await _remoteDataSource.getAvailableGames();
    
    // Cache the results (all games)
    await _localDataSource.cacheGames(dtos);
    
    var games = dtos.map((dto) => dto.toEntity()).toList();
    if (category != null) {
        games = games.where((g) => g.category == category).toList();
    }
    
    return games;
  }

  @override
  Future<List<Game>> getMyJoinedGames() async {
    // Fetch joined games from remote - always fresh data for user's games
    final dtos = await _remoteDataSource.getMyJoinedGames();
    
    // Cache the results
    await _localDataSource.cacheGames(dtos);
    
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<Game>> getGamesNearby({
    required double latitude,
    required double longitude,
    double? maxDistanceKm,
  }) async {
    // Try to get from cache first
    final cachedGames = await _localDataSource.getCachedGamesNearby(
      latitude: latitude,
      longitude: longitude,
      maxDistanceKm: maxDistanceKm,
    );
    
    if (cachedGames.isNotEmpty) {
      // Return cached data immediately
      final games = cachedGames.map((dto) => dto.toEntity()).toList();
      
      // Refresh cache in background
      _refreshGamesCache();
      
      return games;
    }
    
    // Fetch from remote if no cache, then filter by location
    final dtos = await _remoteDataSource.getAvailableGames();
    
    // Cache all games
    await _localDataSource.cacheGames(dtos);
    
    // Filter by location
    final nearbyGames = dtos.where((dto) {
      final entity = dto.toEntity();
      return entity.isWithinDistance(latitude, longitude);
    }).toList();
    
    return nearbyGames.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<Game> getGameById(String gameId) async {
    // Try cache first
    final cachedGame = await _localDataSource.getCachedGame(gameId);
    if (cachedGame != null) {
      // Return cached data and refresh in background
      _refreshGameCache(gameId);
      return cachedGame.toEntity();
    }
    
    // Fetch from remote
    final dto = await _remoteDataSource.getGameById(gameId);
    
    // Cache the result
    await _localDataSource.cacheGame(dto);
    
    return dto.toEntity();
  }

  /// Background refresh for games cache
  Future<void> _refreshGamesCache() async {
    try {
      final dtos = await _remoteDataSource.getAvailableGames();
      await _localDataSource.cacheGames(dtos);
    } catch (e) {
      // Silent fail - we already have cached data
    }
  }

  /// Background refresh for single game cache
  Future<void> _refreshGameCache(String gameId) async {
    try {
      final dto = await _remoteDataSource.getGameById(gameId);
      await _localDataSource.cacheGame(dto);
    } catch (e) {
      // Silent fail - we already have cached data
    }
  }

  @override
  Future<Game> createGame({
    required String title,
    required String description,
    required List<String> tags,
    required int maxPlayers,
    required DateTime endTime,
    XFile? imageFile,
  }) async {
    final dto = await _remoteDataSource.createGame(
      title: title,
      description: description,
      tags: tags,
      maxPlayers: maxPlayers,
      endTime: endTime,
      imageFile: imageFile,
    );
    
    // Cache the new game
    await _localDataSource.cacheGame(dto);
    
    return dto.toEntity();
  }

  @override
  Future<Game> joinGame(String gameId) async {
    final dto = await _remoteDataSource.joinGame(gameId);
    
    // Update cache
    await _localDataSource.cacheGame(dto);
    
    return dto.toEntity();
  }

  @override
  Future<void> leaveGame(String gameId) async {
    await _remoteDataSource.leaveGame(gameId);
    
    // Remove from cache as player is no longer in game
    await _localDataSource.deleteCachedGame(gameId);
  }

  @override
  Future<Game> updateGame(String gameId, Map<String, dynamic> updates) async {
    final dto = await _remoteDataSource.updateGame(gameId, updates);
    
    // Update cache
    await _localDataSource.cacheGame(dto);
    
    return dto.toEntity();
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _remoteDataSource.deleteGame(gameId);
    
    // Remove from cache
    await _localDataSource.deleteCachedGame(gameId);
  }

  @override
  Future<List<ChatMessage>> getChatMessages(String gameId) async {
    // Try to get from cache first
    final cachedMessages = await _chatLocalDataSource.getCachedChatMessages(gameId);
    if (cachedMessages.isNotEmpty) {
      return cachedMessages.map((dto) => dto.toEntity()).toList();
    }
    
    // Fetch from remote if no cache
    final dtos = await _remoteDataSource.getChatMessages(gameId);
    
    // Cache the results
    await _chatLocalDataSource.cacheChatMessages(gameId, dtos);
    
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<ChatMessage> sendChatMessage(String gameId, String message) async {
    final dto = await _remoteDataSource.sendChatMessage(gameId, message);
    
    // Add to cache
    await _chatLocalDataSource.addChatMessage(gameId, dto);
    
    return dto.toEntity();
  }

  @override
  Future<List<GameHistory>> getGameHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final dtos = await _remoteDataSource.getGameHistory(
      page: page,
      limit: limit,
    );
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Stream<Game> watchGame(String gameId) {
    return _remoteDataSource
        .watchGame(gameId)
        .map((dto) => dto.toEntity());
  }

  @override
  Stream<ChatMessage> watchChatMessages(String gameId) {
    return _remoteDataSource
        .watchChatMessages(gameId)
        .map((dto) {
          // Cache each incoming message
          _chatLocalDataSource.addChatMessage(gameId, dto);
          return dto.toEntity();
        });
  }

  @override
  Future<List<Game>> getMyCreatedGames() async {
    final dtos = await _remoteDataSource.getMyCreatedGames();
    
    // Cache optional - maybe separate cache key?
    // For now, let's cache them as general games
    await _localDataSource.cacheGames(dtos);
    
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<String>> getPopularTags() async {
    // Ideally cache tags too, but for now fetch fresh
    return await _remoteDataSource.getPopularTags();
  }
}

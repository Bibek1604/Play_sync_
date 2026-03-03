import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/constants/hive_table_constant.dart';
import '../../domain/entities/game_entity.dart';

/// Repository for game data with Hive cache + API coordination.
///
/// Implements cache-first strategy with TTL (time-to-live) for optimal performance.
/// Cache is automatically invalidated after mutations (join/leave/cancel).
class GameRepository {
  final ApiClient _api;
  late final Box<dynamic> _gamesBox;

  /// Cache TTL — games older than this are refetched from API
  static const _cacheTTL = Duration(minutes: 5);

  GameRepository(this._api) {
    _gamesBox = Hive.box(HiveTableConstant.gamesBox);
  }

  // ─── Single Game Operations ─────────────────────────────────────────────

  /// Fetches a game by ID from cache (if fresh) or API.
  ///
  /// [forceRefresh] bypasses cache and always fetches from API.
  /// Always fetches with full participant details (`?details=true`).
  Future<GameEntity> getGame(String id, {bool forceRefresh = false}) async {
    // 1. Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = _gamesBox.get(id);
      if (cached != null && cached is Map) {
        try {
          final cacheMap = Map<String, dynamic>.from(cached);
          if (_isCacheFresh(cacheMap)) {
            debugPrint('[GameRepository] ✓ Cache hit for game $id');
            return GameEntity.fromJson(cacheMap);
          } else {
            debugPrint('[GameRepository] ⏰ Cache expired for game $id');
          }
        } catch (e) {
          debugPrint('[GameRepository] ⚠️ Cache parse error for game $id: $e');
        }
      }
    } else {
      debugPrint('[GameRepository] 🔄 Force refresh for game $id');
    }

    // 2. Fetch from API with full details
    try {
      final resp = await _api.get(ApiEndpoints.getGameById(id));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final raw = inner['game'] ?? inner;
      final game = GameEntity.fromJson(raw as Map<String, dynamic>);

      // 3. Update cache with timestamp
      await _updateCache(id, game);

      debugPrint('[GameRepository] ✓ Fetched game $id from API');
      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ API fetch failed for game $id: $e');
      rethrow;
    }
  }

  /// Joins a game and returns the updated game entity.
  ///
  /// Cache is updated immediately with the server response.
  Future<GameEntity> joinGame(String id) async {
    try {
      final resp = await _api.post(ApiEndpoints.joinGame(id));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final raw = inner['game'] ?? inner;
      final game = GameEntity.fromJson(raw as Map<String, dynamic>);

      // Update cache immediately after mutation
      await _updateCache(id, game);
      debugPrint('[GameRepository] ✓ Joined game $id, cache updated');

      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Join failed for game $id: $e');
      rethrow;
    }
  }

  /// Leaves a game and returns the updated game entity.
  ///
  /// Cache is updated immediately with the server response.
  Future<GameEntity> leaveGame(String id) async {
    try {
      final resp = await _api.post(ApiEndpoints.leaveGame(id));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final raw = inner['game'] ?? inner;
      final game = GameEntity.fromJson(raw as Map<String, dynamic>);

      // Update cache immediately after mutation
      await _updateCache(id, game);
      debugPrint('[GameRepository] ✓ Left game $id, cache updated');

      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Leave failed for game $id: $e');
      rethrow;
    }
  }

  /// Cancels a game (creator only) and returns updated entity.
  Future<GameEntity> cancelGame(String id) async {
    try {
      await _api.patch(ApiEndpoints.cancelGame(id));

      // Refetch game with updated status
      final game = await getGame(id, forceRefresh: true);
      debugPrint('[GameRepository] ✓ Cancelled game $id, cache updated');

      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Cancel failed for game $id: $e');
      rethrow;
    }
  }

  /// Completes a game (creator only) and returns updated entity.
  Future<GameEntity> completeGame(String id) async {
    try {
      await _api.patch(ApiEndpoints.completeGame(id));

      // Refetch game with updated status
      final game = await getGame(id, forceRefresh: true);
      debugPrint('[GameRepository] ✓ Completed game $id, cache updated');

      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Complete failed for game $id: $e');
      rethrow;
    }
  }

  /// Deletes a game permanently.
  Future<void> deleteGame(String id) async {
    try {
      await _api.delete(ApiEndpoints.deleteGame(id));

      // Remove from cache
      await _gamesBox.delete(id);
      debugPrint('[GameRepository] ✓ Deleted game $id, removed from cache');
    } catch (e) {
      debugPrint('[GameRepository] ❌ Delete failed for game $id: $e');
      rethrow;
    }
  }

  // ─── Bulk Operations ────────────────────────────────────────────────────

  /// Creates a new game.
  /// [gameData] may be a plain [Map] or a Dio [FormData] (for image uploads).
  Future<void> createGame(dynamic gameData) async {
    try {
      final opts = gameData is FormData
          ? Options(contentType: 'multipart/form-data')
          : null;
      await _api.post(ApiEndpoints.createGame, data: gameData, options: opts);
      debugPrint('[GameRepository] ✓ Game created successfully');
    } catch (e) {
      debugPrint('[GameRepository] ❌ Create game failed: $e');
      rethrow;
    }
  }

  /// Fetches paginated game list from API.
  /// Returns games and pagination metadata.
  Future<GameListResult> fetchGames({
    required int page,
    required int limit,
    String? status,
    String? category,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      final resp = await _api.get(
        ApiEndpoints.getGames,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (category != null) 'category': category,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (radius != null) 'radius': radius,
          if (latitude != null && longitude != null) 'sortBy': 'distance',
        },
      );

      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final gamesList = (inner['games'] as List?) ?? [];
      final pagination = (inner['pagination'] as Map<String, dynamic>?) ?? {};

      final games = gamesList
          .map((json) => GameEntity.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache each game individually
      for (final game in games) {
        await _updateCache(game.id, game);
      }

      final hasNext = pagination['hasNext'] as bool? ?? games.length >= limit;

      debugPrint('[GameRepository] ✓ Fetched ${games.length} games (page $page)');

      return GameListResult(games: games, hasMore: hasNext);
    } catch (e) {
      debugPrint('[GameRepository] ❌ Fetch games failed: $e');
      rethrow;
    }
  }

  /// Fetches games created by current user.
  Future<List<GameEntity>> fetchMyCreatedGames() async {
    try {
      final resp = await _api.get(ApiEndpoints.getMyCreatedGames);
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final gamesList = (inner['games'] as List?) ?? [];

      final games = gamesList
          .map((json) => GameEntity.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache each game
      for (final game in games) {
        await _updateCache(game.id, game);
      }

      debugPrint('[GameRepository] ✓ Fetched ${games.length} created games');
      return games;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Fetch my created games failed: $e');
      rethrow;
    }
  }

  /// Fetches games joined by current user.
  Future<List<GameEntity>> fetchMyJoinedGames() async {
    try {
      final resp = await _api.get(ApiEndpoints.getMyJoinedGames);
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final gamesList = (inner['games'] as List?) ?? [];

      final games = gamesList
          .map((json) => GameEntity.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache each game
      for (final game in games) {
        await _updateCache(game.id, game);
      }

      debugPrint('[GameRepository] ✓ Fetched ${games.length} joined games');
      return games;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Fetch my joined games failed: $e');
      rethrow;
    }
  }

  // ─── Cache Management ───────────────────────────────────────────────────

  /// Loads all cached games on app startup.
  List<GameEntity> loadCachedGames() {
    try {
      final cached = _gamesBox.values
          .where((value) => value is Map)
          .map((value) {
            try {
              final map = Map<String, dynamic>.from(value as Map);
              // Only return if cache is fresh
              if (_isCacheFresh(map)) {
                return GameEntity.fromJson(map);
              }
              return null;
            } catch (e) {
              debugPrint('[GameRepository] ⚠️ Failed to parse cached game: $e');
              return null;
            }
          })
          .whereType<GameEntity>()
          .toList();

      debugPrint('[GameRepository] ✓ Loaded ${cached.length} fresh games from cache');
      return cached;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Load cache failed: $e');
      return [];
    }
  }

  /// Updates cache with timestamp for a game.
  Future<void> _updateCache(String id, GameEntity game) async {
    try {
      final json = game.toJson();
      json['_cachedAt'] = DateTime.now().toIso8601String();
      await _gamesBox.put(id, json);
    } catch (e) {
      debugPrint('[GameRepository] ⚠️ Cache update failed for $id: $e');
    }
  }

  /// Returns true if cache entry is fresh (within TTL).
  bool _isCacheFresh(Map<String, dynamic> cached) {
    final cachedAtStr = cached['_cachedAt'] as String?;
    if (cachedAtStr == null) return false;

    final cachedAt = DateTime.tryParse(cachedAtStr);
    if (cachedAt == null) return false;

    return DateTime.now().difference(cachedAt) < _cacheTTL;
  }

  /// Clears all cached games (useful for logout/debugging).
  Future<void> clearCache() async {
    await _gamesBox.clear();
    debugPrint('[GameRepository] ✓ Cache cleared');
  }

  /// Invalidates cache for a specific game (forces refetch next time).
  Future<void> invalidateGame(String id) async {
    await _gamesBox.delete(id);
    debugPrint('[GameRepository] ✓ Cache invalidated for game $id');
  }
}

/// Result object for paginated game list.
class GameListResult {
  final List<GameEntity> games;
  final bool hasMore;

  const GameListResult({required this.games, required this.hasMore});
}

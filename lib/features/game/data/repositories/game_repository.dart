import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/constants/hive_table_constant.dart';
import 'package:play_sync_new/core/services/isolate_service.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/entities/invite_link_entity.dart';
import '../../domain/entities/game_invitation_entity.dart';

/// Repository for game data with Hive cache + API coordination.
/// Implements cache-first strategy with TTL (time-to-live) for optimal performance.
/// Cache is automatically invalidated after mutations (join/leave/cancel).
class GameRepository {
  final ApiClient _api;
  Box<dynamic>? _gamesBox;

  /// Cache TTL — games older than this are refetched from API
  static const _cacheTTL = Duration(minutes: 5);

  GameRepository(this._api);

  /// Safely get the games box, opening it if necessary
  Future<Box<dynamic>> get _box async {
    if (_gamesBox != null && _gamesBox!.isOpen) return _gamesBox!;
    if (!Hive.isBoxOpen(HiveTableConstant.gamesBox)) {
      _gamesBox = await Hive.openBox(HiveTableConstant.gamesBox);
    } else {
      _gamesBox = Hive.box(HiveTableConstant.gamesBox);
    }
    return _gamesBox!;
  }
/// Fetches a game by ID from cache (if fresh) or API.
/// [forceRefresh] bypasses cache and always fetches from API.
  /// Always fetches with full participant details (`?details=true`).
  Future<GameEntity> getGame(String id, {bool forceRefresh = false}) async {
    final box = await _box;
    // 1. Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = box.get(id);
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

  /// Updates an existing game (creator only).
/// [gameData] may be a plain Map or Dio [FormData] (for image uploads).
  /// Returns the updated [GameEntity].
  Future<GameEntity> updateGame(String id, dynamic gameData) async {
    try {
      final opts = gameData is FormData
          ? Options(contentType: 'multipart/form-data')
          : null;
      final resp = await _api.patch(
        ApiEndpoints.updateGame(id),
        data: gameData,
        options: opts,
      );
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final raw = inner['game'] ?? inner;
      final game = GameEntity.fromJson(raw as Map<String, dynamic>);

      await _updateCache(id, game);
      debugPrint('[GameRepository] ✓ Updated game $id, cache refreshed');
      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ Update failed for game $id: $e');
      rethrow;
    }
  }

  /// Checks whether the current user can join a game.
/// Returns `{ canJoin: bool, reason?: String }`.
  Future<({bool canJoin, String? reason})> canJoinGame(String id) async {
    try {
      final resp = await _api.get(ApiEndpoints.canJoinGame(id));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final canJoin = inner['canJoin'] as bool? ?? false;
      final reason = inner['reason'] as String?;
      debugPrint('[GameRepository] ✓ canJoin($id) = $canJoin');
      return (canJoin: canJoin, reason: reason);
    } catch (e) {
      debugPrint('[GameRepository] ❌ canJoinGame failed for $id: $e');
      rethrow;
    }
  }

  /// Fetches popular game tags from the backend.
/// GET /games/tags/popular?limit=[limit]
  Future<List<String>> fetchPopularTags({int limit = 20}) async {
    try {
      final resp = await _api.get(
        ApiEndpoints.getPopularTags,
        queryParameters: {'limit': limit},
      );
      final body = resp.data as Map<String, dynamic>;
      final inner = body['data'];
      if (inner is List) {
        return inner.map((e) => e.toString()).toList();
      }
      debugPrint('[GameRepository] ✓ Fetched popular tags');
      return [];
    } catch (e) {
      debugPrint('[GameRepository] ❌ fetchPopularTags failed: $e');
      return [];
    }
  }
/// Generates an invite link for a game (creator only).
/// POST /games/:id/invite
  /// Returns [InviteLink] with code, expiry, and full URL.
  Future<InviteLink> generateInviteLink(String gameId) async {
    try {
      final resp = await _api.post(ApiEndpoints.generateInviteLink(gameId));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      debugPrint('[GameRepository] ✓ Generated invite link for game $gameId');
      return InviteLink.fromJson(inner);
    } catch (e) {
      debugPrint('[GameRepository] ❌ generateInviteLink failed: $e');
      rethrow;
    }
  }

  /// Fetches invite details for a given invite code.
/// GET /games/invite/:code (public — no auth middleware in route)
  /// Returns basic game info to show before joining.
  Future<InviteDetails> getInviteDetails(String code) async {
    try {
      final resp = await _api.get(ApiEndpoints.getInviteDetails(code));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      debugPrint('[GameRepository] ✓ Fetched invite details for code $code');
      return InviteDetails.fromJson(inner);
    } catch (e) {
      debugPrint('[GameRepository] ❌ getInviteDetails failed: $e');
      rethrow;
    }
  }

  /// Joins a game via invite code. Returns the updated game.
/// POST /games/invite/:code/join
  Future<GameEntity> joinViaInvite(String code) async {
    try {
      final resp = await _api.post(ApiEndpoints.joinViaInvite(code));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final raw = inner['game'] ?? inner;
      final game = GameEntity.fromJson(raw as Map<String, dynamic>);
      await _updateCache(game.id, game);
      debugPrint('[GameRepository] ✓ Joined via invite code $code → game ${game.id}');
      return game;
    } catch (e) {
      debugPrint('[GameRepository] ❌ joinViaInvite failed: $e');
      rethrow;
    }
  }
/// Sends a game invitation to a specific user.
/// POST /games/:gameId/invite  body: { invitedUserId, message? }
  Future<GameInvitation> sendInvitation({
    required String gameId,
    required String invitedUserId,
    String? message,
  }) async {
    try {
      final resp = await _api.post(
        ApiEndpoints.sendGameInvitation(gameId),
        data: {
          'invitedUserId': invitedUserId,
          if (message != null) 'message': message,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      debugPrint('[GameRepository] ✓ Invitation sent for game $gameId');
      return GameInvitation.fromJson(inner);
    } catch (e) {
      debugPrint('[GameRepository] ❌ sendInvitation failed: $e');
      rethrow;
    }
  }

  /// Fetches all invitations received by the current user.
/// GET /games/me/invitations
  Future<List<GameInvitation>> getMyInvitations() async {
    try {
      final resp = await _api.get(ApiEndpoints.getMyInvitations);
      final body = resp.data as Map<String, dynamic>;
      final inner = body['data'];
      if (inner is List) {
        return inner
            .map((j) => GameInvitation.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[GameRepository] ❌ getMyInvitations failed: $e');
      return [];
    }
  }

  /// Responds to a game invitation (accept / decline).
/// PUT /games/invitations/:invitationId/respond  body: { action }
  Future<void> respondToInvitation({
    required String invitationId,
    required InvitationAction action,
  }) async {
    try {
      await _api.put(
        ApiEndpoints.respondToInvitation(invitationId),
        data: {'action': action.name},
      );
      debugPrint('[GameRepository] ✓ Responded ${action.name} to invitation $invitationId');
    } catch (e) {
      debugPrint('[GameRepository] ❌ respondToInvitation failed: $e');
      rethrow;
    }
  }

  /// Deletes a game permanently.
  Future<void> deleteGame(String id) async {
    try {
      await _api.delete(ApiEndpoints.deleteGame(id));

      // Remove from cache
      final box = await _box;
      await box.delete(id);
      debugPrint('[GameRepository] ✓ Deleted game $id, removed from cache');
    } catch (e) {
      debugPrint('[GameRepository] ❌ Delete failed for game $id: $e');
      rethrow;
    }
  }
/// Creates a new game and returns the created [GameEntity].
  /// [gameData] may be a plain [Map] or a Dio [FormData] (for image uploads).
  Future<GameEntity> createGame(dynamic gameData) async {
    try {
      final opts = gameData is FormData
          ? Options(contentType: 'multipart/form-data')
          : null;
      final resp = await _api.post(ApiEndpoints.createGame, data: gameData, options: opts);
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final raw = inner['game'] ?? inner;
      final game = GameEntity.fromJson(raw as Map<String, dynamic>);

      // Cache the newly created game
      await _updateCache(game.id, game);
      debugPrint('[GameRepository] ✓ Game created successfully: ${game.id}');
      return game;
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
    bool? excludeMe,
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
          if (excludeMe != null) 'excludeMe': excludeMe,
          if (latitude != null && longitude != null) 'sortBy': 'distance',
        },
      );

      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final gamesList = (inner['games'] as List?) ?? [];
      final pagination = (inner['pagination'] as Map<String, dynamic>?) ?? {};

      final games = await IsolateService.run(
        GameEntity.fromJsonList,
        gamesList,
        debugName: 'Parse Games (fetchGames)',
      );

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

      final games = await IsolateService.run(
        GameEntity.fromJsonList,
        gamesList,
        debugName: 'Parse Created Games',
      );

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

      final games = await IsolateService.run(
        GameEntity.fromJsonList,
        gamesList,
        debugName: 'Parse Joined Games',
      );

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
/// Loads all cached games on app startup.
  Future<List<GameEntity>> loadCachedGames() async {
    try {
      final box = await _box;
      final rawValues = box.values
          .where((v) => v is Map)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .where((m) => _isCacheFresh(m))
          .toList();

      if (rawValues.isEmpty) return [];

      final cached = await IsolateService.run(
        GameEntity.fromJsonList,
        rawValues,
        debugName: 'Parse Cached Games',
      );

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
      final box = await _box;
      final json = game.toJson();
      json['_cachedAt'] = DateTime.now().toIso8601String();
      await box.put(id, json);
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
    final box = await _box;
    await box.clear();
    debugPrint('[GameRepository] ✓ Cache cleared');
  }

  /// Invalidates cache for a specific game (forces refetch next time).
  Future<void> invalidateGame(String id) async {
    final box = await _box;
    await box.delete(id);
    debugPrint('[GameRepository] ✓ Cache invalidated for game $id');
  }
}

/// Result object for paginated game list.
class GameListResult {
  final List<GameEntity> games;
  final bool hasMore;

  const GameListResult({required this.games, required this.hasMore});
}

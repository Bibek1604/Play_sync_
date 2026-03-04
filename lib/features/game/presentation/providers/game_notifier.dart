import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/entities/invite_link_entity.dart';
import '../../domain/entities/game_invitation_entity.dart';
import '../../data/repositories/game_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum GameFilter { all, OPEN, FULL, ENDED, CANCELLED }

class GameState extends Equatable {
  final List<GameEntity> games;
  final List<GameEntity> myCreatedGames;
  final List<GameEntity> myJoinedGames;
  final List<GameEntity> availableGames; // Games for discovery (not created/joined)
  final bool isLoading;
  final String? error;
  final GameFilter filter;
  final String? categoryFilter; // "ONLINE" | "OFFLINE"
  final bool hasMore;
  final int page;

  // Current game being viewed (for detail page state sync)
  final GameEntity? currentGame;

  // Location-based filtering (offline games)
  final double? nearLatitude;
  final double? nearLongitude;
  final double nearRadius; // km — backend default is 10km

  // Popular tags
  final List<String> popularTags;

  // Game invitations received by current user
  final List<GameInvitation> myInvitations;

  const GameState({
    this.games = const [],
    this.myCreatedGames = const [],
    this.myJoinedGames = const [],
    this.availableGames = const [],
    this.isLoading = false,
    this.error,
    this.filter = GameFilter.all,
    this.categoryFilter,
    this.hasMore = true,
    this.page = 1,
    this.currentGame,
    this.nearLatitude,
    this.nearLongitude,
    this.nearRadius = 10,
    this.popularTags = const [],
    this.myInvitations = const [],
  });

  List<GameEntity> get filteredGames {
    return games.where((g) {
      final statusMatch = switch (filter) {
        GameFilter.all => true,
        GameFilter.OPEN => g.status == GameStatus.OPEN,
        GameFilter.FULL => g.status == GameStatus.FULL,
        GameFilter.ENDED => g.status == GameStatus.ENDED,
        GameFilter.CANCELLED => g.status == GameStatus.CANCELLED,
      };
      final categoryMatch = categoryFilter == null || g.category == categoryFilter;
      return statusMatch && categoryMatch;
    }).toList();
  }

  List<GameEntity> get onlineGames => games.where((g) => g.isOnline).toList();
  List<GameEntity> get offlineGames => games.where((g) => g.isOffline).toList();
  List<GameEntity> get openGames => games.where((g) => g.isOpen).toList();

  GameState copyWith({
    List<GameEntity>? games,
    List<GameEntity>? myCreatedGames,
    List<GameEntity>? myJoinedGames,
    List<GameEntity>? availableGames,
    bool? isLoading,
    String? error,
    GameFilter? filter,
    String? categoryFilter,
    bool? hasMore,
    int? page,
    GameEntity? currentGame,
    bool clearCurrentGame = false,
    bool clearError = false,
    bool clearCategory = false,
    double? nearLatitude,
    double? nearLongitude,
    double? nearRadius,
    bool clearLocation = false,
    List<String>? popularTags,
    List<GameInvitation>? myInvitations,
  }) {
    return GameState(
      games: games ?? this.games,
      myCreatedGames: myCreatedGames ?? this.myCreatedGames,
      myJoinedGames: myJoinedGames ?? this.myJoinedGames,
      availableGames: availableGames ?? this.availableGames,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      currentGame: clearCurrentGame ? null : (currentGame ?? this.currentGame),
      nearLatitude: clearLocation ? null : (nearLatitude ?? this.nearLatitude),
      nearLongitude: clearLocation ? null : (nearLongitude ?? this.nearLongitude),
      nearRadius: nearRadius ?? this.nearRadius,
      popularTags: popularTags ?? this.popularTags,
      myInvitations: myInvitations ?? this.myInvitations,
    );
  }

  bool get hasLocationFilter => nearLatitude != null && nearLongitude != null;

  @override
  List<Object?> get props => [
        games, myCreatedGames, myJoinedGames, availableGames, isLoading, error,
        filter, categoryFilter, hasMore, page, currentGame,
        nearLatitude, nearLongitude, nearRadius,
        popularTags, myInvitations,
      ];
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class GameNotifier extends StateNotifier<GameState> {
  final GameRepository _repository;
  
  GameNotifier(this._repository) : super(const GameState()) {
    // Load from cache first (instant display)
    loadFromCache();
    // Then fetch fresh data in background
    fetchGames();
  }

  /// Loads games from Hive cache on app startup for instant display.
  Future<void> loadFromCache() async {
    final cached = await _repository.loadCachedGames();
    if (cached.isNotEmpty) {
      state = state.copyWith(games: cached, isLoading: false);
      debugPrint('[GameNotifier] ✓ Loaded ${cached.length} games from cache');
    }
  }

  Future<void> fetchGames({bool refresh = false, bool excludeMe = false}) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, clearError: true, page: page);
    try {
      final result = await _repository.fetchGames(
        page: page,
        limit: 20,
        status: state.filter != GameFilter.all ? state.filter.name : null,
        category: state.categoryFilter,
        latitude: state.nearLatitude,
        longitude: state.nearLongitude,
        radius: state.hasLocationFilter ? state.nearRadius : null,
        excludeMe: excludeMe,
      );
      
      if (excludeMe) {
        state = state.copyWith(
          availableGames: refresh ? result.games : [...state.availableGames, ...result.games],
          isLoading: false,
          hasMore: result.hasMore,
          page: page + 1,
        );
      } else {
        state = state.copyWith(
          games: refresh ? result.games : [...state.games, ...result.games],
          isLoading: false,
          hasMore: result.hasMore,
          page: page + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMsg(e));
    }
  }

  /// Sets a location filter and refreshes the game list.
  /// [latitude] & [longitude] in degrees, [radius] in km (default 10km).
  void setLocationFilter(double latitude, double longitude, {double radius = 10}) {
    state = state.copyWith(
      nearLatitude: latitude,
      nearLongitude: longitude,
      nearRadius: radius,
      games: [],
      page: 1,
      hasMore: true,
    );
    fetchGames(refresh: true);
  }

  /// Removes the location filter, showing all games.
  void clearLocationFilter() {
    state = state.copyWith(clearLocation: true, games: [], page: 1, hasMore: true);
    fetchGames(refresh: true);
  }

  Future<void> fetchMyCreatedGames() async {
    try {
      final games = await _repository.fetchMyCreatedGames();
      debugPrint('[GameNotifier] Fetched ${games.length} created games');
      state = state.copyWith(myCreatedGames: games);
    } catch (e) {
      debugPrint('[GameNotifier] fetchMyCreatedGames error: ${e.toString()}');
    }
  }

  Future<void> fetchMyJoinedGames() async {
    try {
      final games = await _repository.fetchMyJoinedGames();
      debugPrint('[GameNotifier] Fetched ${games.length} joined games');
      state = state.copyWith(myJoinedGames: games);
    } catch (e) {
      debugPrint('[GameNotifier] fetchMyJoinedGames error: ${e.toString()}');
    }
  }

  /// Fetches a game by ID and updates currentGame state.
  /// Always fetches fresh data from backend with full participant details.
  /// [forceRefresh] bypasses cache and always fetches from API.
  Future<GameEntity?> fetchGameById(String id, {bool forceRefresh = false}) async {
    try {
      final game = await _repository.getGame(id, forceRefresh: forceRefresh);
      
      // Update currentGame state for UI reactivity
      state = state.copyWith(currentGame: game);
      
      // Update in games list if present
      final updatedGames = state.games.map((g) => g.id == id ? game : g).toList();
      state = state.copyWith(games: updatedGames);
      
      return game;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// [gameData] may be a plain [Map] or a Dio [FormData] (for image uploads).
  /// Returns the created [GameEntity] on success, or null on failure.
  Future<GameEntity?> createGame(dynamic gameData) async {
    try {
      final game = await _repository.createGame(gameData);

      // Immediately add to lists for instant UI update
      state = state.copyWith(
        myCreatedGames: [game, ...state.myCreatedGames],
        myJoinedGames: [game, ...state.myJoinedGames], // Added this
        games: [game, ...state.games],
      );

      // Refresh to get server-authoritative data
      // Await myCreatedGames to ensure creator status is properly recognized
      await fetchMyCreatedGames();
      // Background refresh of all games
      fetchGames(refresh: true);

      return game;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// Joins a game and returns the updated game entity.
  /// Ensures state is synchronized across all lists and currentGame.
  Future<GameEntity?> joinGame(String gameId) async {
    try {
      // Join via repository (updates cache automatically)
      final updatedGame = await _repository.joinGame(gameId);
      
      // Update currentGame state for UI reactivity
      state = state.copyWith(currentGame: updatedGame);
      
      // Update in games list if present
      final updatedGames = state.games.map((g) => g.id == gameId ? updatedGame : g).toList();
      state = state.copyWith(games: updatedGames);
      
      // Update joined games list in background
      fetchMyJoinedGames();
      
      return updatedGame;
    } catch (e) {
      final msg = _errorMsg(e);
      // If the backend says we've already joined, we should treat it as a success 
      // and just fetch the details to sync our state.
      if (msg.contains('already joined') || msg.contains('Already joined')) {
        debugPrint('[GameNotifier] Already joined detected, fetching game details instead.');
        return await fetchGameById(gameId, forceRefresh: true);
      }
      state = state.copyWith(error: msg);
      return null;
    }
  }

  /// Leaves a game and returns the updated game entity.
  /// Ensures state is synchronized across all lists and currentGame.
  Future<GameEntity?> leaveGame(String gameId) async {
    try {
      // Leave via repository (updates cache automatically)
      final updatedGame = await _repository.leaveGame(gameId);
      
      // Update currentGame state for UI reactivity
      state = state.copyWith(currentGame: updatedGame);
      
      // Update in games list if present
      final updatedGames = state.games.map((g) => g.id == gameId ? updatedGame : g).toList();
      state = state.copyWith(games: updatedGames);
      
      // Update joined games list in background
      fetchMyJoinedGames();
      
      return updatedGame;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  Future<bool> deleteGame(String gameId) async {
    try {
      // 1. Backend deletion
      await _repository.deleteGame(gameId);
      
      // 2. Immediate local state cleanup for "WOW" real-time feel
      state = state.copyWith(
        games: state.games.where((g) => g.id != gameId).toList(),
        myCreatedGames: state.myCreatedGames.where((g) => g.id != gameId).toList(),
        myJoinedGames: state.myJoinedGames.where((g) => g.id != gameId).toList(),
        clearCurrentGame: state.currentGame?.id == gameId,
      );

      debugPrint('[GameNotifier] ✓ Game $gameId deleted, state updated locally');

      // 3. Refresh lists in background to ensure consistency
      fetchGames(refresh: true);
      fetchMyCreatedGames();
      fetchMyJoinedGames();

      return true;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  /// Cancels a game (creator only) and returns updated game entity.
  Future<GameEntity?> cancelGame(String gameId) async {
    try {
      final updatedGame = await _repository.cancelGame(gameId);
      
      // Update currentGame state
      state = state.copyWith(currentGame: updatedGame);
      
      // Update in games list if present
      final updatedGames = state.games.map((g) => g.id == gameId ? updatedGame : g).toList();
      state = state.copyWith(games: updatedGames);
      
      // Refresh lists in background
      fetchGames(refresh: true);
      
      return updatedGame;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// Completes a game (creator only) and returns updated game entity.
  Future<GameEntity?> completeGame(String gameId) async {
    try {
      final updatedGame = await _repository.completeGame(gameId);
      
      // Update currentGame state
      state = state.copyWith(currentGame: updatedGame);
      
      // Update in games list if present
      final updatedGames = state.games.map((g) => g.id == gameId ? updatedGame : g).toList();
      state = state.copyWith(games: updatedGames);
      
      // Refresh lists in background
      fetchGames(refresh: true);
      
      return updatedGame;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  // ─── Update Game ─────────────────────────────────────────────────────────

  /// Updates an existing game (creator only).
  /// [gameData] may be a plain Map or Dio FormData (for image uploads).
  Future<GameEntity?> updateGame(String gameId, dynamic gameData) async {
    try {
      final updatedGame = await _repository.updateGame(gameId, gameData);

      state = state.copyWith(currentGame: updatedGame);

      final updatedGames = state.games.map((g) => g.id == gameId ? updatedGame : g).toList();
      final updatedCreated = state.myCreatedGames.map((g) => g.id == gameId ? updatedGame : g).toList();
      state = state.copyWith(games: updatedGames, myCreatedGames: updatedCreated);

      return updatedGame;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  // ─── Can Join Check ───────────────────────────────────────────────────────

  /// Checks if the current user can join a game.
  /// Returns `(canJoin, reason?)` without mutating state.
  Future<({bool canJoin, String? reason})> canJoinGame(String gameId) async {
    try {
      return await _repository.canJoinGame(gameId);
    } catch (e) {
      return (canJoin: false, reason: _errorMsg(e));
    }
  }

  // ─── Tags ─────────────────────────────────────────────────────────────────

  /// Fetches popular tags and updates state.
  Future<void> fetchPopularTags({int limit = 20}) async {
    try {
      final tags = await _repository.fetchPopularTags(limit: limit);
      state = state.copyWith(popularTags: tags);
    } catch (_) {
      // Non-critical — silently ignore
    }
  }

  // ─── Invite Link ──────────────────────────────────────────────────────────

  /// Generates a shareable invite link for a game (creator only).
  Future<InviteLink?> generateInviteLink(String gameId) async {
    try {
      return await _repository.generateInviteLink(gameId);
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// Fetches game details for an invite code (to show preview before joining).
  Future<InviteDetails?> getInviteDetails(String code) async {
    try {
      return await _repository.getInviteDetails(code);
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// Joins a game using an invite code.
  Future<GameEntity?> joinViaInvite(String code) async {
    try {
      final game = await _repository.joinViaInvite(code);

      state = state.copyWith(
        currentGame: game,
        games: [game, ...state.games],
      );
      fetchMyJoinedGames();
      return game;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  // ─── Game Invitations ─────────────────────────────────────────────────────

  /// Sends an invitation to a user for a specific game.
  Future<GameInvitation?> sendInvitation({
    required String gameId,
    required String invitedUserId,
    String? message,
  }) async {
    try {
      return await _repository.sendInvitation(
        gameId: gameId,
        invitedUserId: invitedUserId,
        message: message,
      );
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// Fetches all invitations received by the current user.
  Future<void> fetchMyInvitations() async {
    try {
      final invitations = await _repository.getMyInvitations();
      state = state.copyWith(myInvitations: invitations);
    } catch (_) {
      // Non-critical — silently ignore
    }
  }

  /// Responds to an invitation (accept / decline) and refreshes list.
  Future<bool> respondToInvitation({
    required String invitationId,
    required InvitationAction action,
  }) async {
    try {
      await _repository.respondToInvitation(
        invitationId: invitationId,
        action: action,
      );
      // Refresh invitations and joined games
      fetchMyInvitations();
      if (action == InvitationAction.accept) {
        fetchMyJoinedGames();
        fetchGames(refresh: true);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  /// Fetches offline games, optionally filtered by proximity.
  /// Resets category to 'OFFLINE' and updates location state atomically.
  Future<void> fetchOfflineGamesNearby({
    double? latitude,
    double? longitude,
    double radius = 10,
  }) async {
    state = state.copyWith(
      categoryFilter: 'OFFLINE',
      nearLatitude: latitude,
      nearLongitude: longitude,
      nearRadius: radius,
      games: [],
      page: 1,
      hasMore: true,
      clearLocation: latitude == null,
    );
    await fetchGames(refresh: true);
  }

  void setFilter(GameFilter f) {
    state = state.copyWith(filter: f, games: [], page: 1, hasMore: true);
    fetchGames(refresh: true);
  }

  void setCategoryFilter(String? c) {
    state = state.copyWith(categoryFilter: c, games: [], page: 1, hasMore: true, clearCategory: c == null);
    fetchGames(refresh: true);
  }

  // helpers
  String _errorMsg(dynamic e) {
    if (e is DioException) {
      final msg = (e.response?.data is Map) ? (e.response!.data as Map)['message'] : null;
      return msg?.toString() ?? e.message ?? 'Something went wrong';
    }
    return e.toString();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Repository provider for game data with Hive cache coordination
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return GameRepository(api);
});

/// Main game state provider (singleton)
final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.watch(gameRepositoryProvider)),
);

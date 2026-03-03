import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/entities/game_entity.dart';
import '../../data/repositories/game_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum GameFilter { all, OPEN, FULL, ENDED, CANCELLED }

class GameState extends Equatable {
  final List<GameEntity> games;
  final List<GameEntity> myCreatedGames;
  final List<GameEntity> myJoinedGames;
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

  const GameState({
    this.games = const [],
    this.myCreatedGames = const [],
    this.myJoinedGames = const [],
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
  }) {
    return GameState(
      games: games ?? this.games,
      myCreatedGames: myCreatedGames ?? this.myCreatedGames,
      myJoinedGames: myJoinedGames ?? this.myJoinedGames,
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
    );
  }

  bool get hasLocationFilter => nearLatitude != null && nearLongitude != null;

  @override
  List<Object?> get props => [
        games, myCreatedGames, myJoinedGames, isLoading, error,
        filter, categoryFilter, hasMore, page, currentGame,
        nearLatitude, nearLongitude, nearRadius,
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
  void loadFromCache() {
    final cached = _repository.loadCachedGames();
    if (cached.isNotEmpty) {
      state = state.copyWith(games: cached, isLoading: false);
      debugPrint('[GameNotifier] ✓ Loaded ${cached.length} games from cache');
    }
  }

  Future<void> fetchGames({bool refresh = false}) async {
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
      );
      
      state = state.copyWith(
        games: refresh ? result.games : [...state.games, ...result.games],
        isLoading: false,
        hasMore: result.hasMore,
        page: page + 1,
      );
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
      state = state.copyWith(myCreatedGames: games);
    } catch (e) {
      debugPrint('[GameNotifier] fetchMyCreatedGames error: ${e.toString()}');
    }
  }

  Future<void> fetchMyJoinedGames() async {
    try {
      final games = await _repository.fetchMyJoinedGames();
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
  Future<bool> createGame(dynamic gameData) async {
    try {
      await _repository.createGame(gameData);
      await fetchGames(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
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
      state = state.copyWith(error: _errorMsg(e));
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
      await _repository.deleteGame(gameId);
      await fetchGames(refresh: true);
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

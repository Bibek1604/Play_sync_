import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/game_entity.dart';

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
      nearLatitude: clearLocation ? null : (nearLatitude ?? this.nearLatitude),
      nearLongitude: clearLocation ? null : (nearLongitude ?? this.nearLongitude),
      nearRadius: nearRadius ?? this.nearRadius,
    );
  }

  bool get hasLocationFilter => nearLatitude != null && nearLongitude != null;

  @override
  List<Object?> get props => [
        games, myCreatedGames, myJoinedGames, isLoading, error,
        filter, categoryFilter, hasMore, page,
        nearLatitude, nearLongitude, nearRadius,
      ];
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class GameNotifier extends StateNotifier<GameState> {
  final ApiClient _api;
  GameNotifier(this._api) : super(const GameState()) {
    fetchGames();
  }

  Future<void> fetchGames({bool refresh = false}) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, clearError: true, page: page);
    try {
      final resp = await _api.get(
        ApiEndpoints.getGames,
        queryParameters: {
          'page': page,
          'limit': 20,
          if (state.filter != GameFilter.all) 'status': state.filter.name,
          if (state.categoryFilter != null) 'category': state.categoryFilter,
          // Location-based filtering
          if (state.nearLatitude != null) 'latitude': state.nearLatitude,
          if (state.nearLongitude != null) 'longitude': state.nearLongitude,
          if (state.hasLocationFilter) 'radius': state.nearRadius,
          if (state.hasLocationFilter) 'sortBy': 'distance',
        },
      );
      // Backend: { success, message, data: { games: [], pagination: {} } }
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      final list = _parseGameList(inner['games'] ?? []);
      final pagination = inner['pagination'] as Map<String, dynamic>? ?? {};
      final hasNext = pagination['hasNext'] as bool? ?? list.length >= 20;
      state = state.copyWith(
        games: refresh ? list : [...state.games, ...list],
        isLoading: false,
        hasMore: hasNext,
        page: page + 1,
      );
    } on DioException catch (e) {
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
      final resp = await _api.get(ApiEndpoints.getMyCreatedGames);
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      state = state.copyWith(myCreatedGames: _parseGameList(inner['games'] ?? []));
    } on DioException catch (e) {
      debugPrint('[GameNotifier] fetchMyCreatedGames error: ${e.message}');
    }
  }

  Future<void> fetchMyJoinedGames() async {
    try {
      final resp = await _api.get(ApiEndpoints.getMyJoinedGames);
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      state = state.copyWith(myJoinedGames: _parseGameList(inner['games'] ?? []));
    } on DioException catch (e) {
      debugPrint('[GameNotifier] fetchMyJoinedGames error: ${e.message}');
    }
  }

  Future<GameEntity?> fetchGameById(String id) async {
    try {
      final resp = await _api.get(ApiEndpoints.getGameById(id));
      final body = resp.data as Map<String, dynamic>;
      final inner = (body['data'] as Map<String, dynamic>?) ?? body;
      // Backend: { data: { game: {...} } } or { data: { ...game fields... } }
      final raw = inner['game'] ?? inner;
      return GameEntity.fromJson(raw as Map<String, dynamic>);
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return null;
    }
  }

  /// [gameData] may be a plain [Map] or a Dio [FormData] (for image uploads).
  Future<bool> createGame(dynamic gameData) async {
    try {
      final opts = gameData is FormData
          ? Options(contentType: 'multipart/form-data')
          : null;
      await _api.post(ApiEndpoints.createGame, data: gameData, options: opts);
      await fetchGames(refresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  Future<bool> joinGame(String gameId) async {
    try {
      await _api.post(ApiEndpoints.joinGame(gameId));
      await fetchGames(refresh: true);
      await fetchMyJoinedGames(); // keep joined-games list in sync
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  Future<bool> leaveGame(String gameId) async {
    try {
      await _api.post(ApiEndpoints.leaveGame(gameId));
      await fetchGames(refresh: true);
      await fetchMyJoinedGames(); // remove from joined-games list
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  Future<bool> deleteGame(String gameId) async {
    try {
      await _api.delete(ApiEndpoints.deleteGame(gameId));
      await fetchGames(refresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  Future<bool> cancelGame(String gameId) async {
    try {
      await _api.patch(ApiEndpoints.cancelGame(gameId));
      await fetchGames(refresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _errorMsg(e));
      return false;
    }
  }

  Future<bool> completeGame(String gameId) async {
    try {
      await _api.patch(ApiEndpoints.completeGame(gameId));
      await fetchGames(refresh: true);
      return true;
    } on DioException catch (e) {
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
  List<GameEntity> _parseGameList(dynamic raw) {
    if (raw is List) {
      return raw.map((j) => GameEntity.fromJson(j as Map<String, dynamic>)).toList();
    }
    return [];
  }

  String _errorMsg(DioException e) {
    final msg = (e.response?.data is Map) ? (e.response!.data as Map)['message'] : null;
    return msg?.toString() ?? e.message ?? 'Something went wrong';
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.watch(apiClientProvider)),
);

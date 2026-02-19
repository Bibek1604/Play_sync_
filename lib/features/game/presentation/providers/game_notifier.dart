import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/game_entity.dart';
import '../../../../../core/api/api_endpoints.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum GameFilter { all, upcoming, live, completed }

class GameState extends Equatable {
  final List<GameEntity> games;
  final bool isLoading;
  final String? error;
  final GameFilter filter;
  final GameCategory? categoryFilter;
  final bool hasMore;
  final int page;

  const GameState({
    this.games = const [],
    this.isLoading = false,
    this.error,
    this.filter = GameFilter.all,
    this.categoryFilter,
    this.hasMore = true,
    this.page = 1,
  });

  List<GameEntity> get filteredGames {
    return games.where((g) {
      final statusMatch = switch (filter) {
        GameFilter.all => true,
        GameFilter.upcoming => g.status == GameStatus.upcoming,
        GameFilter.live => g.status == GameStatus.live,
        GameFilter.completed => g.status == GameStatus.completed,
      };
      final categoryMatch = categoryFilter == null || g.category == categoryFilter;
      return statusMatch && categoryMatch;
    }).toList();
  }

  GameState copyWith({
    List<GameEntity>? games,
    bool? isLoading,
    String? error,
    GameFilter? filter,
    GameCategory? categoryFilter,
    bool? hasMore,
    int? page,
    bool clearError = false,
    bool clearCategory = false,
  }) {
    return GameState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [games, isLoading, error, filter, categoryFilter, hasMore, page];
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class GameNotifier extends StateNotifier<GameState> {
  final Dio _dio;
  GameNotifier(this._dio) : super(const GameState()) {
    fetchGames();
  }

  Future<void> fetchGames({bool refresh = false}) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, clearError: true, page: page);
    try {
      final resp = await _dio.get(
        '${ApiEndpoints.baseUrl}/games',
        queryParameters: {
          'page': page,
          'limit': 20,
          if (state.filter != GameFilter.all) 'status': state.filter.name,
          if (state.categoryFilter != null) 'category': state.categoryFilter!.name,
        },
      );
      final data = resp.data as Map<String, dynamic>;
      final list = (data['games'] as List? ?? [])
          .map((j) => GameEntity.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        games: refresh ? list : [...state.games, ...list],
        isLoading: false,
        hasMore: list.length >= 20,
        page: page + 1,
      );
    } on DioException catch (e) {
      // Offline / demo: generate mock games
      if (refresh || state.games.isEmpty) {
        state = state.copyWith(games: _mockGames(), isLoading: false, hasMore: false);
      } else {
        state = state.copyWith(isLoading: false, error: e.message);
      }
    }
  }

  void setFilter(GameFilter f) {
    state = state.copyWith(filter: f, games: [], page: 1, hasMore: true);
    fetchGames(refresh: true);
  }

  void setCategoryFilter(GameCategory? c) {
    state = state.copyWith(categoryFilter: c, games: [], page: 1, hasMore: true, clearCategory: c == null);
    fetchGames(refresh: true);
  }

  Future<void> joinGame(String gameId) async {
    try {
      await _dio.post('${ApiEndpoints.baseUrl}/games/$gameId/join');
      await fetchGames(refresh: true);
    } on DioException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> leaveGame(String gameId) async {
    try {
      await _dio.post('${ApiEndpoints.baseUrl}/games/$gameId/leave');
      await fetchGames(refresh: true);
    } on DioException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  List<GameEntity> _mockGames() => [
    GameEntity(
      id: 'g1', title: 'Weekend Football', description: 'Friendly 5-a-side match',
      category: GameCategory.football, status: GameStatus.upcoming,
      hostId: 'u1', hostName: 'Alex', maxPlayers: 10, currentPlayers: 6,
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      location: 'Central Park Field', isOnline: false, participantIds: [],
    ),
    GameEntity(
      id: 'g2', title: 'Chess Tournament', description: 'Online rapid chess',
      category: GameCategory.chess, status: GameStatus.live,
      hostId: 'u2', hostName: 'Robin', maxPlayers: 16, currentPlayers: 16,
      scheduledAt: DateTime.now(), isOnline: true, participantIds: [],
    ),
    GameEntity(
      id: 'g3', title: 'Basketball Pickup', description: '3v3 half court game',
      category: GameCategory.basketball, status: GameStatus.upcoming,
      hostId: 'u3', hostName: 'Jordan', maxPlayers: 6, currentPlayers: 2,
      scheduledAt: DateTime.now().add(const Duration(hours: 6)),
      location: 'City Gym', isOnline: false, participantIds: [],
    ),
    GameEntity(
      id: 'g4', title: 'Badminton Singles', description: 'Best of 3 sets',
      category: GameCategory.badminton, status: GameStatus.completed,
      hostId: 'u4', hostName: 'Sam', maxPlayers: 2, currentPlayers: 2,
      scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
      location: 'Sports Hall', isOnline: false, participantIds: [],
    ),
    GameEntity(
      id: 'g5', title: 'Cricket T20', description: 'T20 format match',
      category: GameCategory.cricket, status: GameStatus.upcoming,
      hostId: 'u5', hostName: 'Raj', maxPlayers: 22, currentPlayers: 14,
      scheduledAt: DateTime.now().add(const Duration(days: 5)),
      location: 'Cricket Ground', isOnline: false, participantIds: [],
    ),
  ];
}

// ─── Providers ───────────────────────────────────────────────────────────────

final _dioProvider = Provider<Dio>((ref) => Dio());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.watch(_dioProvider)),
);

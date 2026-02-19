import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/services/socket_service.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_game_by_id.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

/// Game Real-Time State
class GameRealtimeState {
  final Game? game;
  final bool isLoading;
  final String? error;
  final List<String> recentNotifications;

  GameRealtimeState({
    this.game,
    this.isLoading = false,
    this.error,
    this.recentNotifications = const [],
  });

  GameRealtimeState copyWith({
    Game? game,
    bool? isLoading,
    String? error,
    List<String>? recentNotifications,
    bool clearError = false,
  }) {
    return GameRealtimeState(
      game: game ?? this.game,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }
}

/// Game Real-Time Notifier
///
/// Manages real-time updates for a specific game.
/// Listens to socket events: game:status:changed, game:player_joined, game:player_left
class GameRealtimeNotifier extends StateNotifier<GameRealtimeState> {
  final String gameId;
  final GetGameById _getGameById;
  final SocketService _socketService;

  GameRealtimeNotifier({
    required this.gameId,
    required GetGameById getGameById,
    required SocketService socketService,
  })  : _getGameById = getGameById,
        _socketService = socketService,
        super(GameRealtimeState()) {
    _init();
  }

  void _init() {
    loadGame();
    _subscribeToSocket();
  }

  /// Load initial game data
  Future<void> loadGame() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final game = await _getGameById(gameId);
      state = state.copyWith(game: game, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Subscribe to socket events
  void _subscribeToSocket() {
    // Subscribe without entering lobby (no system message, no presence tracking)
    _socketService.emitWithAck(ApiEndpoints.socketSubscribeGame, gameId);

    // Listen for real-time game status change (OPEN → FULL → ENDED → CANCELLED)
    _socketService.on(ApiEndpoints.socketGameStatusChanged, _onGameStatusChanged);

    // Listen for player join/leave events
    _socketService.on(ApiEndpoints.socketPlayerJoined, _onPlayerJoined);
    _socketService.on(ApiEndpoints.socketPlayerLeft, _onPlayerLeft);
  }

  /// Handle game status change event
  /// Payload: { gameId, status, availableSlots, timestamp }
  void _onGameStatusChanged(dynamic data) {
    if (data == null || data is! Map) return;
    final eventGameId = data['gameId']?.toString();
    if (eventGameId != null && eventGameId != gameId) return;

    try {
      final statusStr = data['status']?.toString();
      if (statusStr == null) return;

      final newStatus = GameStatus.fromString(statusStr);
      final availableSlots = data['availableSlots'] as int?;

      if (state.game != null) {
        final updatedGame = state.game!.copyWith(
          status: newStatus,
          currentPlayers: availableSlots != null
              ? state.game!.maxPlayers - availableSlots
              : null,
        );
        state = state.copyWith(game: updatedGame);
      } else {
        // Game not loaded yet, reload from server
        loadGame();
      }
    } catch (e) {
      // If parsing fails, reload the game from server
      loadGame();
    }
  }

  /// Handle player joined event
  void _onPlayerJoined(dynamic data) {
    if (data == null || data is! Map) return;
    final eventGameId = data['gameId']?.toString();
    if (eventGameId != null && eventGameId != gameId) return;

    try {
      final playerName = data['username']?.toString() ??
          data['player']?['username']?.toString() ??
          'Someone';
      final notification = '$playerName joined the game';

      state = state.copyWith(
        recentNotifications: [
          notification,
          ...state.recentNotifications.take(4).toList(),
        ],
      );

      // Reload game to get updated player list & slot count
      loadGame();
    } catch (e) {
      loadGame();
    }
  }

  /// Handle player left event
  void _onPlayerLeft(dynamic data) {
    if (data == null || data is! Map) return;
    final eventGameId = data['gameId']?.toString();
    if (eventGameId != null && eventGameId != gameId) return;

    try {
      final playerName = data['username']?.toString() ??
          data['player']?['username']?.toString() ??
          'Someone';
      final notification = '$playerName left the game';

      state = state.copyWith(
        recentNotifications: [
          notification,
          ...state.recentNotifications.take(4).toList(),
        ],
      );

      loadGame();
    } catch (e) {
      loadGame();
    }
  }

  /// Clear notifications
  void clearNotifications() {
    state = state.copyWith(recentNotifications: []);
  }

  @override
  void dispose() {
    _socketService.off(ApiEndpoints.socketGameStatusChanged, _onGameStatusChanged);
    _socketService.off(ApiEndpoints.socketPlayerJoined, _onPlayerJoined);
    _socketService.off(ApiEndpoints.socketPlayerLeft, _onPlayerLeft);
    super.dispose();
  }
}

/// Game Real-Time Provider (Family)
///
/// Usage: ref.watch(gameRealtimeProvider(gameId))
final gameRealtimeProvider = StateNotifierProvider.family.autoDispose<
    GameRealtimeNotifier, GameRealtimeState, String>((ref, gameId) {
  return GameRealtimeNotifier(
    gameId: gameId,
    getGameById: ref.watch(getGameByIdUseCaseProvider),
    socketService: ref.watch(socketServiceProvider),
  );
});


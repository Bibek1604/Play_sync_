import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_available_games.dart';
import 'package:play_sync_new/features/game/domain/usecases/create_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/join_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/delete_game.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

/// Game List State
class GameListState {
  final List<Game> games;
  final bool isLoading;
  final String? error;

  GameListState({
    this.games = const [],
    this.isLoading = false,
    this.error,
  });

  GameListState copyWith({
    List<Game>? games,
    bool? isLoading,
    String? error,
  }) {
    return GameListState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Game List Notifier
class GameListNotifier extends StateNotifier<GameListState> {
  final GetAvailableGames _getAvailableGames;
  final CreateGame _createGame;
  final JoinGame _joinGame;
  final DeleteGame _deleteGame;

  GameListNotifier(
    this._getAvailableGames,
    this._createGame,
    this._joinGame,
    this._deleteGame,
  ) : super(GameListState());

  /// Load available games
  Future<void> loadGames() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final games = await _getAvailableGames();
      state = state.copyWith(
        games: games,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh games list
  Future<void> refresh() => loadGames();

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Create a new game
  /// Returns the created game ID
  Future<String> createGame({
    required String title,
    required String description,
    required List<String> tags,
    required int maxPlayers,
    required DateTime endTime,
    XFile? imageFile,
  }) async {
    try {
      final game = await _createGame(CreateGameParams(
        title: title,
        description: description,
        tags: tags,
        maxPlayers: maxPlayers,
        endTime: endTime,
        imageFile: imageFile,
      ));

      // Refresh the games list to include the new game
      await loadGames();

      return game.id;
    } catch (e) {
      throw Exception('Failed to create game: ${e.toString()}');
    }
  }

  /// Join a game
  Future<void> joinGame(String gameId) async {
    try {
      await _joinGame(gameId);
      
      // Refresh the games list to update player counts
      await loadGames();
    } catch (e) {
      throw Exception('Failed to join game: ${e.toString()}');
    }
  }

  /// Delete a game (creator only)
  Future<void> deleteGame(String gameId) async {
    try {
      await _deleteGame(gameId);
      // Remove from state immediately
      state = state.copyWith(
        games: state.games.where((g) => g.id != gameId).toList(),
      );
    } catch (e) {
      throw Exception('Failed to delete game: ${e.toString()}');
    }
  }
}

/// Game List Provider
final gameListProvider =
    StateNotifierProvider<GameListNotifier, GameListState>((ref) {
  return GameListNotifier(
    ref.watch(getAvailableGamesUseCaseProvider),
    ref.watch(createGameUseCaseProvider),
    ref.watch(joinGameUseCaseProvider),
    ref.watch(deleteGameUseCaseProvider),
  );
});

/// Current authenticated user ID
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(authNotifierProvider).user?.userId ?? '';
});

final onlineGamesProvider = Provider<List<Game>>((ref) {
  final gameState = ref.watch(gameListProvider);
  return gameState.games.where((game) => game.isOnline).toList();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_my_joined_games.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

/// Joined Games State
class JoinedGamesState {
  final List<Game> games;
  final bool isLoading;
  final String? error;

  JoinedGamesState({
    this.games = const [],
    this.isLoading = false,
    this.error,
  });

  JoinedGamesState copyWith({
    List<Game>? games,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return JoinedGamesState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Active chatable games: only OPEN or FULL games have live chat
  List<Game> get activeChatGames => games
      .where((g) =>
          g.status == GameStatus.open || g.status == GameStatus.full)
      .toList();
}

/// Joined Games Notifier
class JoinedGamesNotifier extends StateNotifier<JoinedGamesState> {
  final GetMyJoinedGames _getMyJoinedGames;

  JoinedGamesNotifier(this._getMyJoinedGames) : super(JoinedGamesState());

  /// Load user's joined games
  Future<void> loadJoinedGames() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final games = await _getMyJoinedGames();
      state = state.copyWith(games: games, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh joined games list
  Future<void> refresh() => loadJoinedGames();

  /// Immediately remove a game by ID from the local list (e.g. after leaving)
  void removeGame(String gameId) {
    state = state.copyWith(
      games: state.games.where((g) => g.id != gameId).toList(),
    );
  }

  /// Update a game's status in local state (from socket events)
  void updateGameStatus(String gameId, GameStatus newStatus) {
    final updatedGames = state.games.map((g) {
      if (g.id == gameId) return g.copyWith(status: newStatus);
      return g;
    }).toList();
    state = state.copyWith(games: updatedGames);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Joined Games Provider
final joinedGamesProvider =
    StateNotifierProvider<JoinedGamesNotifier, JoinedGamesState>((ref) {
  return JoinedGamesNotifier(
    ref.watch(getMyJoinedGamesUseCaseProvider),
  );
});

import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Join Game Use Case
class JoinGame {
  final GameRepository repository;

  JoinGame(this.repository);

  Future<Game> call(String gameId) async {
    // Business logic validation
    if (gameId.trim().isEmpty) {
      throw Exception('Game ID cannot be empty');
    }

    // Get game details first to check if it's full
    final game = await repository.getGameById(gameId);

    if (game.isFull) {
      throw Exception('Game is full');
    }

    if (game.status != GameStatus.open) {
      throw Exception('Game is not accepting players');
    }

    return await repository.joinGame(gameId);
  }
}

import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Leave Game Use Case
class LeaveGame {
  final GameRepository repository;

  LeaveGame(this.repository);

  Future<void> call(String gameId) async {
    if (gameId.trim().isEmpty) {
      throw Exception('Game ID cannot be empty');
    }

    await repository.leaveGame(gameId);
  }
}

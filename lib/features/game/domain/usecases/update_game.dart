import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class UpdateGame {
  final GameRepository _repository;

  UpdateGame(this._repository);

  Future<Game> call(String gameId, Map<String, dynamic> updates) {
    return _repository.updateGame(gameId, updates);
  }
}

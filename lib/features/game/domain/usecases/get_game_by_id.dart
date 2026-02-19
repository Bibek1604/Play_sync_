import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class GetGameById {
  final GameRepository _repository;

  GetGameById(this._repository);

  Future<Game> call(String gameId) {
    return _repository.getGameById(gameId);
  }
}

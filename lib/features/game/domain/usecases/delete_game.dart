import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class DeleteGame {
  final GameRepository _repository;

  DeleteGame(this._repository);

  Future<void> call(String gameId) {
    return _repository.deleteGame(gameId);
  }
}

import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class GetMyCreatedGames {
  final GameRepository _repository;

  GetMyCreatedGames(this._repository);

  Future<List<Game>> call() {
    return _repository.getMyCreatedGames();
  }
}

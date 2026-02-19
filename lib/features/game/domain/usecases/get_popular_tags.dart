import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class GetPopularTags {
  final GameRepository _repository;

  GetPopularTags(this._repository);

  Future<List<String>> call() {
    return _repository.getPopularTags();
  }
}

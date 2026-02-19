import 'package:play_sync_new/features/game/domain/entities/game_history.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Get Game History Use Case
class GetGameHistory {
  final GameRepository repository;

  GetGameHistory(this.repository);

  Future<List<GameHistory>> call({int page = 1, int limit = 20}) async {
    if (page < 1) {
      throw Exception('Page must be greater than 0');
    }

    if (limit < 1 || limit > 100) {
      throw Exception('Limit must be between 1 and 100');
    }

    return await repository.getGameHistory(page: page, limit: limit);
  }
}

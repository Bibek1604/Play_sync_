import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Get Available Games Use Case
/// 
/// Fetches all available games that can be joined
class GetAvailableGames {
  final GameRepository repository;

  GetAvailableGames(this.repository);

  Future<List<Game>> call({GameCategory? category}) async {
    return await repository.getAvailableGames(category: category);
  }
}

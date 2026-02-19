import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Get My Joined Games Use Case
/// 
/// Fetches all games that the current user has joined
class GetMyJoinedGames {
  final GameRepository repository;

  GetMyJoinedGames(this.repository);

  Future<List<Game>> call() async {
    return await repository.getMyJoinedGames();
  }
}

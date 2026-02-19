import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/game/domain/entities/game_stats.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class GetGameStatsParams {
  final String gameId;
  const GetGameStatsParams({required this.gameId});
}

/// Retrieves post-game statistics for the given game session.
class GetGameStatsUsecase
    implements UsecaseWithParams<GameStats, GetGameStatsParams> {
  final IGameRepository _repository;

  const GetGameStatsUsecase({required IGameRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, GameStats>> call(GetGameStatsParams params) {
    return _repository.getGameStats(gameId: params.gameId);
  }
}

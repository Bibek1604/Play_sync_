import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class FavoriteGameParams {
  final String gameId;
  final bool isFavorite;

  const FavoriteGameParams({required this.gameId, required this.isFavorite});
}

/// Toggles the favourite status of a game for the current user.
class FavoriteGameUsecase
    implements UsecaseWithParams<Game, FavoriteGameParams> {
  final IGameRepository _repository;

  const FavoriteGameUsecase({required IGameRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, Game>> call(FavoriteGameParams params) {
    return _repository.toggleFavorite(
      gameId: params.gameId,
      isFavorite: params.isFavorite,
    );
  }
}

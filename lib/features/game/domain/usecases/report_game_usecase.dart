import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class ReportGameParams {
  final String gameId;
  final String reason;
  final String? details;

  const ReportGameParams({
    required this.gameId,
    required this.reason,
    this.details,
  });
}

/// Reports a game to moderators with a reason and optional details.
class ReportGameUsecase
    implements UsecaseWithParams<void, ReportGameParams> {
  final IGameRepository _repository;

  const ReportGameUsecase({required IGameRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, void>> call(ReportGameParams params) {
    return _repository.reportGame(
      gameId: params.gameId,
      reason: params.reason,
      details: params.details,
    );
  }
}

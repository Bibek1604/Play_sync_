import 'package:dartz/dartz.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';
import 'package:play_sync_new/features/game/domain/value_objects/game_filter.dart';
import 'package:play_sync_new/features/game/domain/value_objects/game_sort_type.dart';

class SearchGamesParams {
  final String query;
  final GameFilter filter;
  final GameSortType sortBy;
  final int page;
  final int pageSize;

  const SearchGamesParams({
    required this.query,
    this.filter = const GameFilter(),
    this.sortBy = GameSortType.newest,
    this.page = 1,
    this.pageSize = 20,
  });
}

/// Searches available games by text query with optional filter and sort.
class SearchGamesUsecase
    implements UsecaseWithParams<List<Game>, SearchGamesParams> {
  final IGameRepository _repository;

  const SearchGamesUsecase({required IGameRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<Game>>> call(SearchGamesParams params) {
    return _repository.searchGames(
      query: params.query,
      filter: params.filter,
      sortBy: params.sortBy,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

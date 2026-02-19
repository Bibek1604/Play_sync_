import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/error/failures.dart';
import 'package:play_sync_new/core/usecases/app_usecases.dart';
import 'package:play_sync_new/features/profile/domain/entities/profile_stats.dart';
import 'package:play_sync_new/features/profile/domain/repositories/profile_repository.dart';

/// Fetches aggregated statistics for the currently authenticated user.
class GetProfileStatsUsecase
    implements UsecaseWithoutParams<ProfileStats> {
  final IProfileRepository _repository;

  const GetProfileStatsUsecase({required IProfileRepository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, ProfileStats>> call() {
    return _repository.getMyStats();
  }
}

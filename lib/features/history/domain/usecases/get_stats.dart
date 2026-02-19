import 'package:play_sync_new/features/history/domain/entities/participation_stats.dart';
import 'package:play_sync_new/features/history/domain/repositories/history_repository.dart';

class GetStats {
  final HistoryRepository repository;

  GetStats(this.repository);

  Future<ParticipationStats> call() async {
    return await repository.getStats();
  }
}

import 'package:play_sync_new/features/scorecard/domain/entities/points_trend.dart';
import 'package:play_sync_new/features/scorecard/domain/repositories/scorecard_repository.dart';

class GetTrend {
  final ScorecardRepository repository;

  GetTrend(this.repository);

  Future<List<PointsTrend>> call({int days = 7}) async {
    if (days < 1 || days > 365) {
      throw ArgumentError('Days must be between 1 and 365');
    }

    return await repository.getTrend(days: days);
  }
}

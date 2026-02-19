import 'package:play_sync_new/features/scorecard/domain/entities/points_trend.dart';
import 'package:play_sync_new/features/scorecard/domain/entities/scorecard.dart';

abstract class ScorecardRepository {
  /// Get user's scorecard
  Future<Scorecard> getMyScorecard();

  /// Get points trend over time
  Future<List<PointsTrend>> getTrend({int days = 7});
}

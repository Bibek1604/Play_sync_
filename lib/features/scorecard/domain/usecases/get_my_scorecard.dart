import 'package:play_sync_new/features/scorecard/domain/entities/scorecard.dart';
import 'package:play_sync_new/features/scorecard/domain/repositories/scorecard_repository.dart';

class GetMyScorecard {
  final ScorecardRepository repository;

  GetMyScorecard(this.repository);

  Future<Scorecard> call() async {
    return await repository.getMyScorecard();
  }
}

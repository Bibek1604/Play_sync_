import 'package:play_sync_new/features/history/domain/repositories/history_repository.dart';

class GetMyHistory {
  final HistoryRepository repository;

  GetMyHistory(this.repository);

  Future<HistoryListResult> call({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    // Validation
    if (page < 1) {
      throw ArgumentError('Page must be at least 1');
    }
    
    if (limit < 1 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }

    if (status != null && !['completed', 'cancelled', 'active'].contains(status)) {
      throw ArgumentError('Invalid status. Must be completed, cancelled, or active');
    }

    return await repository.getMyHistory(
      page: page,
      limit: limit,
      status: status,
    );
  }
}

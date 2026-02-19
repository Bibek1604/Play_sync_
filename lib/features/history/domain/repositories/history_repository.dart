import 'package:play_sync_new/features/history/domain/entities/game_history.dart';
import 'package:play_sync_new/features/history/domain/entities/participation_stats.dart';

abstract class HistoryRepository {
  /// Get user's game history with pagination
  Future<HistoryListResult> getMyHistory({
    int page = 1,
    int limit = 10,
    String? status,
  });

  /// Get user's participation statistics
  Future<ParticipationStats> getStats();

  /// Get total count of games played
  Future<int> getCount();
}

class HistoryListResult {
  final List<GameHistory> history;
  final PaginationMeta pagination;

  HistoryListResult({
    required this.history,
    required this.pagination,
  });
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;

  PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  bool get hasPrevious => page > 1;
}

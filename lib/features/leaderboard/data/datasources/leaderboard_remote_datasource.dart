import 'package:dio/dio.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/leaderboard/data/models/leaderboard_entry_dto.dart';

class LeaderboardRemoteDataSource {
  final Dio dio;

  LeaderboardRemoteDataSource(this.dio);

  Future<List<LeaderboardEntryDto>> getLeaderboard({
    required int page,
    required int limit,
    required String period,
  }) async {
    try {
      final response = await dio.get(
        ApiEndpoints.leaderboardList,
        queryParameters: {
          'page': page,
          'limit': limit,
          'period': period,
        },
      );

      // Backend wraps response in: { success, message, data: { leaderboard: [...], pagination: {...} } }
      final data = response.data['data'] ?? response.data;
      final leaderboardData = data['leaderboard'] ?? data;

      if (leaderboardData is List) {
        return leaderboardData
            .map((item) => LeaderboardEntryDto.fromJson(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getStats() async {
    try {
      final response = await dio.get(ApiEndpoints.leaderboardStats);
      
      // Backend wraps response in: { success, message, data: { totalPlayers: number } }
      final data = response.data['data'] ?? response.data;
      
      return data['totalPlayers'] ?? data['total_players'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['message'] ?? 
                     error.response?.data['error'] ??
                     'An error occurred';
      return Exception(message);
    }
    return Exception('Network error: ${error.message}');
  }
}

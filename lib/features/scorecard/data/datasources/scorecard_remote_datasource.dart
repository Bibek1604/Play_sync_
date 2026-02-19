import 'package:dio/dio.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/scorecard/data/models/points_trend_dto.dart';
import 'package:play_sync_new/features/scorecard/data/models/scorecard_dto.dart';

class ScorecardRemoteDataSource {
  final Dio dio;

  ScorecardRemoteDataSource(this.dio);

  Future<ScorecardDto> getMyScorecard() async {
    try {
      final response = await dio.get(ApiEndpoints.scorecardGet);
      final data = response.data['data'] ?? response.data;
      
      if (data == null || data is! Map) {
        // Return default scorecard if no data
        return ScorecardDto(points: 0, rank: 0, gamesPlayed: 0);
      }
      
      return ScorecardDto.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      print('[ScorecardDataSource] Error: ${e.message}');
      // Return default scorecard instead of throwing to avoid UI crashes
      return ScorecardDto(points: 0, rank: 0, gamesPlayed: 0);
    }
  }

  Future<List<PointsTrendDto>> getTrend({required int days}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.scorecardTrend,
        queryParameters: {'days': days},
      );

      final data = response.data['data'] ?? response.data;
      
      if (data is List) {
        return data
            .map((item) => PointsTrendDto.fromJson(item))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('[ScorecardDataSource] Error fetching trend: ${e.message}');
      return [];
    }
  }
}

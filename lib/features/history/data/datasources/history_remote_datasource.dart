import 'package:dio/dio.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/features/history/data/models/game_history_dto.dart';
import 'package:play_sync_new/features/history/data/models/participation_stats_dto.dart';

class HistoryRemoteDataSource {
  final Dio dio;

  HistoryRemoteDataSource(this.dio);

  Future<HistoryListResultDto> getMyHistory({
    required int page,
    required int limit,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await dio.get(
        ApiEndpoints.historyList,
        queryParameters: queryParams,
      );

      final data = response.data['data'] ?? response.data;
      
      return HistoryListResultDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ParticipationStatsDto> getStats() async {
    try {
      final response = await dio.get(ApiEndpoints.historyStats);
      final data = response.data['data'] ?? response.data;
      
      return ParticipationStatsDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getCount() async {
    try {
      final response = await dio.get(ApiEndpoints.historyCount);
      final data = response.data['data'] ?? response.data;
      
      // Handle both direct number and object with count property
      if (data is int) {
        return data;
      } else if (data is Map && data['count'] != null) {
        return data['count'];
      }
      
      return 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['message'] ?? 'An error occurred';
      return Exception(message);
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return Exception('Receive timeout');
    } else {
      return Exception('Network error');
    }
  }
}

class HistoryListResultDto {
  final List<GameHistoryDto> history;
  final PaginationDto pagination;

  HistoryListResultDto({
    required this.history,
    required this.pagination,
  });

  factory HistoryListResultDto.fromJson(Map<String, dynamic> json) {
    final historyList = json['history'] as List<dynamic>? ?? [];
    
    return HistoryListResultDto(
      history: historyList
          .map((item) => GameHistoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationDto.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationDto {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;

  PaginationDto({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  factory PaginationDto.fromJson(Map<String, dynamic> json) {
    return PaginationDto(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 0,
      hasNext: json['hasNext'] ?? json['has_next'] ?? false,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/features/history/domain/repositories/history_repository.dart';
import 'package:play_sync_new/features/history/domain/usecases/get_my_history.dart';
import 'package:play_sync_new/features/history/domain/usecases/get_stats.dart';
import 'package:play_sync_new/features/history/domain/usecases/get_count.dart';
import 'package:play_sync_new/features/history/data/repositories/history_repository_impl.dart';
import 'package:play_sync_new/features/history/data/datasources/history_remote_datasource.dart';
import 'package:play_sync_new/features/history/data/datasources/history_local_datasource.dart';
import 'package:play_sync_new/features/history/data/models/game_history_dto.dart';

/// Dependency Injection Providers for History Feature

// Dio provider
final historyDioProvider = Provider<Dio>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.dio;
});

// Hive box providers
final historyBoxProvider = Provider<Box<GameHistoryDto>>((ref) {
  return Hive.box<GameHistoryDto>('history');
});

final historyMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('history_metadata');
});

// Remote data source provider
final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  return HistoryRemoteDataSource(ref.watch(historyDioProvider));
});

// Local data source provider
final historyLocalDataSourceProvider = Provider<HistoryLocalDataSource>((ref) {
  return HistoryLocalDataSource(
    ref.watch(historyBoxProvider),
    ref.watch(historyMetadataBoxProvider),
  );
});

// Repository provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(
    ref.watch(historyRemoteDataSourceProvider),
    ref.watch(historyLocalDataSourceProvider),
  );
});

// Use case providers
final getMyHistoryUseCaseProvider = Provider<GetMyHistory>((ref) {
  return GetMyHistory(ref.watch(historyRepositoryProvider));
});

final getStatsUseCaseProvider = Provider<GetStats>((ref) {
  return GetStats(ref.watch(historyRepositoryProvider));
});

final getCountUseCaseProvider = Provider<GetCount>((ref) {
  return GetCount(ref.watch(historyRepositoryProvider));
});

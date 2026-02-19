import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/features/scorecard/domain/repositories/scorecard_repository.dart';
import 'package:play_sync_new/features/scorecard/domain/usecases/get_my_scorecard.dart';
import 'package:play_sync_new/features/scorecard/domain/usecases/get_trend.dart';
import 'package:play_sync_new/features/scorecard/data/repositories/scorecard_repository_impl.dart';
import 'package:play_sync_new/features/scorecard/data/datasources/scorecard_remote_datasource.dart';
import 'package:play_sync_new/features/scorecard/data/datasources/scorecard_local_datasource.dart';
import 'package:hive/hive.dart';

/// Dependency Injection Providers for Scorecard Feature

// Dio provider
final scorecardDioProvider = Provider<Dio>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.dio;
});

// Remote data source provider
final scorecardRemoteDataSourceProvider = Provider<ScorecardRemoteDataSource>((ref) {
  return ScorecardRemoteDataSource(ref.watch(scorecardDioProvider));
});

// Hive box provider
final scorecardMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('scorecard_metadata');
});

// Local data source provider
final scorecardLocalDataSourceProvider = Provider<ScorecardLocalDataSource>((ref) {
  return ScorecardLocalDataSource(ref.watch(scorecardMetadataBoxProvider));
});

// Repository provider
final scorecardRepositoryProvider = Provider<ScorecardRepository>((ref) {
  return ScorecardRepositoryImpl(
    ref.watch(scorecardRemoteDataSourceProvider),
    ref.watch(scorecardLocalDataSourceProvider),
  );
});

// Use case providers
final getScorecardUseCaseProvider = Provider<GetMyScorecard>((ref) {
  return GetMyScorecard(ref.watch(scorecardRepositoryProvider));
});

final getTrendUseCaseProvider = Provider<GetTrend>((ref) {
  return GetTrend(ref.watch(scorecardRepositoryProvider));
});

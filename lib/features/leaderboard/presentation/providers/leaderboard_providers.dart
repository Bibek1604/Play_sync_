import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:play_sync_new/features/leaderboard/domain/usecases/get_leaderboard.dart';
import 'package:play_sync_new/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:play_sync_new/features/leaderboard/data/datasources/leaderboard_remote_datasource.dart';
import 'package:play_sync_new/features/leaderboard/data/datasources/leaderboard_local_datasource.dart';

/// Dependency Injection Providers for Leaderboard Feature

// Dio provider
final leaderboardDioProvider = Provider<Dio>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.dio;
});

// Hive box provider
final leaderboardMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('leaderboard_metadata');
});

// Remote data source provider
final leaderboardRemoteDataSourceProvider = Provider<LeaderboardRemoteDataSource>((ref) {
  return LeaderboardRemoteDataSource(ref.watch(leaderboardDioProvider));
});

// Local data source provider
final leaderboardLocalDataSourceProvider = Provider<LeaderboardLocalDataSource>((ref) {
  return LeaderboardLocalDataSource(ref.watch(leaderboardMetadataBoxProvider));
});

// Repository provider
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepositoryImpl(
    ref.watch(leaderboardRemoteDataSourceProvider),
    ref.watch(leaderboardLocalDataSourceProvider),
  );
});

// Use case providers
final getLeaderboardUseCaseProvider = Provider<GetLeaderboard>((ref) {
  return GetLeaderboard(ref.watch(leaderboardRepositoryProvider));
});

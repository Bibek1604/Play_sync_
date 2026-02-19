import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:play_sync_new/core/api/api_client.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_available_games.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_my_joined_games.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_games_nearby.dart';
import 'package:play_sync_new/features/game/domain/usecases/create_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/join_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/leave_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/send_chat_message.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_game_history.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_my_created_games.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_popular_tags.dart';
import 'package:play_sync_new/features/game/domain/usecases/update_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/delete_game.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_game_by_id.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_chat_messages.dart';
import 'package:play_sync_new/features/game/data/repositories/game_repository_impl.dart';
import 'package:play_sync_new/features/game/data/datasources/game_remote_datasource.dart';
import 'package:play_sync_new/features/game/data/datasources/game_local_datasource.dart';
import 'package:play_sync_new/features/game/data/datasources/chat_local_datasource.dart';
import 'package:play_sync_new/features/game/data/models/game_dto.dart';
import 'package:play_sync_new/core/services/socket_service.dart';

/// Dependency Injection Providers

// Dio provider - uses centralized API client
final dioProvider = Provider<Dio>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.dio;
});

// Socket service provider
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});

// Hive boxes providers
final gamesBoxProvider = Provider<Box<GameDto>>((ref) {
  return Hive.box<GameDto>('games');
});

final gameMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('game_metadata');
});

final chatMetadataBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>('chat_metadata');
});

// Remote data source provider
final gameRemoteDataSourceProvider = Provider<GameRemoteDataSource>((ref) {
  return GameRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(socketServiceProvider),
  );
});

// Local data source provider
final gameLocalDataSourceProvider = Provider<GameLocalDataSource>((ref) {
  return GameLocalDataSource(
    ref.watch(gamesBoxProvider),
    ref.watch(gameMetadataBoxProvider),
  );
});

// Chat local data source provider
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  return ChatLocalDataSource(
    ref.watch(chatMetadataBoxProvider),
  );
});

// Repository provider
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(
    ref.watch(gameRemoteDataSourceProvider),
    ref.watch(gameLocalDataSourceProvider),
    ref.watch(chatLocalDataSourceProvider),
  );
});

// Use case providers
final getAvailableGamesUseCaseProvider = Provider<GetAvailableGames>((ref) {
  return GetAvailableGames(ref.watch(gameRepositoryProvider));
});

final getMyJoinedGamesUseCaseProvider = Provider<GetMyJoinedGames>((ref) {
  return GetMyJoinedGames(ref.watch(gameRepositoryProvider));
});

final getGamesNearbyUseCaseProvider = Provider<GetGamesNearby>((ref) {
  return GetGamesNearby(ref.watch(gameRepositoryProvider));
});

final createGameUseCaseProvider = Provider<CreateGame>((ref) {
  return CreateGame(ref.watch(gameRepositoryProvider));
});

final joinGameUseCaseProvider = Provider<JoinGame>((ref) {
  return JoinGame(ref.watch(gameRepositoryProvider));
});

final leaveGameUseCaseProvider = Provider<LeaveGame>((ref) {
  return LeaveGame(ref.watch(gameRepositoryProvider));
});

final sendChatMessageUseCaseProvider = Provider<SendChatMessage>((ref) {
  return SendChatMessage(ref.watch(gameRepositoryProvider));
});

final getGameHistoryUseCaseProvider = Provider<GetGameHistory>((ref) {
  return GetGameHistory(ref.watch(gameRepositoryProvider));
});

final getMyCreatedGamesUseCaseProvider = Provider<GetMyCreatedGames>((ref) {
  return GetMyCreatedGames(ref.watch(gameRepositoryProvider));
});

final getPopularTagsUseCaseProvider = Provider<GetPopularTags>((ref) {
  return GetPopularTags(ref.watch(gameRepositoryProvider));
});

final updateGameUseCaseProvider = Provider<UpdateGame>((ref) {
  return UpdateGame(ref.watch(gameRepositoryProvider));
});

final deleteGameUseCaseProvider = Provider<DeleteGame>((ref) {
  return DeleteGame(ref.watch(gameRepositoryProvider));
});

final getGameByIdUseCaseProvider = Provider<GetGameById>((ref) {
  return GetGameById(ref.watch(gameRepositoryProvider));
});

final getChatMessagesUseCaseProvider = Provider<GetChatMessages>((ref) {
  return GetChatMessages(ref.watch(gameRepositoryProvider));
});

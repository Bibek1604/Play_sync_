import 'package:flutter/foundation.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/game_chat_repository.dart';
import '../datasources/game_chat_remote_datasource.dart';

/// Concrete implementation of [GameChatRepository].
/// Wraps [GameChatRemoteDatasource] and converts any thrown exceptions
/// into descriptive error messages that the notifier can surface to the UI.
class GameChatRepositoryImpl implements GameChatRepository {
  final GameChatRemoteDatasource _datasource;

  GameChatRepositoryImpl(this._datasource);

  @override
  Future<List<MessageEntity>> fetchMessages(String gameId) async {
    try {
      return await _datasource.fetchMessages(gameId);
    } catch (e) {
      debugPrint('[GameChatRepo] fetchMessages error: $e');
      throw _mapError(e);
    }
  }

  @override
  Future<MessageEntity> sendMessage(String gameId, String text) async {
    try {
      return await _datasource.sendMessage(gameId, text);
    } catch (e) {
      debugPrint('[GameChatRepo] sendMessage error: $e');
      throw _mapError(e);
    }
  }

  /// Maps raw exceptions to user-readable strings.
  Exception _mapError(Object e) {
    final msg = e.toString();
    if (msg.contains('403')) {
      return Exception('You must be an active participant to access chat.');
    }
    if (msg.contains('401')) {
      return Exception('Session expired. Please log in again.');
    }
    if (msg.contains('404')) {
      return Exception('Game not found.');
    }
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return Exception('No internet connection. Please check your network.');
    }
    return Exception('Something went wrong. Please try again.');
  }
}

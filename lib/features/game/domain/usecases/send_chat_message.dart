import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

/// Send Chat Message Use Case
class SendChatMessage {
  final GameRepository repository;

  SendChatMessage(this.repository);

  Future<ChatMessage> call(String gameId, String message) async {
    // Business logic validation
    if (gameId.trim().isEmpty) {
      throw Exception('Game ID cannot be empty');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    if (message.length > 500) {
      throw Exception('Message is too long (max 500 characters)');
    }

    return await repository.sendChatMessage(gameId, message.trim());
  }
}

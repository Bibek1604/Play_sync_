import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';

class GetChatMessages {
  final GameRepository _repository;

  GetChatMessages(this._repository);

  Future<List<ChatMessage>> call(String gameId) {
    return _repository.getChatMessages(gameId);
  }
}

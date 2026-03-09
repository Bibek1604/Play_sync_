import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';
import '../../data/datasources/game_chat_remote_datasource.dart';
import '../../data/repositories/game_chat_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/game_chat_repository.dart';
import '../state/game_chat_state.dart';
import '../../../game/domain/entities/game_entity.dart';
/// Exposes the datasource to the DI graph.
final gameChatDatasourceProvider = Provider<GameChatRemoteDatasource>((ref) {
  return GameChatRemoteDatasource(ref.watch(apiClientProvider));
});

/// Exposes the repository to the DI graph.
final gameChatRepositoryProvider = Provider<GameChatRepository>((ref) {
  return GameChatRepositoryImpl(ref.watch(gameChatDatasourceProvider));
});

/// Shared information about the current user for chat alignment.
class CurrentUserInfo {
  final String id;
  final String name;
  const CurrentUserInfo({this.id = '', this.name = ''});

  bool get isEmpty => id.isEmpty && name.isEmpty;
}

/// Synchronous provider for the current user's profile info.
/// Reacts instantly to auth state changes, ensuring chat alignment (isMe) 
/// never flickers or defaults to "Other" (Left) while loading a Future.
final currentUserInfoProvider = Provider<CurrentUserInfo>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final vmState = ref.watch(authViewModelProvider);

  final authUser = authState.user ?? vmState.user;
  final id = GameEntity.normalize(authUser?.userId);
  final name = (authUser?.fullName ?? '').trim();

  // If in-memory state is empty, this provider will update as soon as 
  // AuthNotifier finishes its _init() and pushes a new state.
  return CurrentUserInfo(id: id, name: name);
});

/// Per-game chat notifier. Create a new provider per [gameId] by using
/// [gameChatNotifierProvider(gameId)].
final gameChatNotifierProvider =
    StateNotifierProvider.family<GameChatNotifier, GameChatState, String>(
  (ref, gameId) {
    final repo = ref.watch(gameChatRepositoryProvider);
    return GameChatNotifier(repo, gameId);
  },
);
/// Manages chat state for a single game room.
/// STRICT SEND FLOW:
///   1. Mark isSending = true.
///   2. POST via repository.
///   3. Append ONLY the server-returned message.
///   4. Mark isSending = false.
///   5. Never call fetchMessages after sending.
class GameChatNotifier extends StateNotifier<GameChatState> {
  final GameChatRepository _repo;
  final String _gameId;

  GameChatNotifier(this._repo, this._gameId) : super(const GameChatState());
/// Loads the complete chat history for [_gameId].
/// Called once when the chat room opens. Replaces any existing list.
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final msgs = await _repo.fetchMessages(_gameId);

      // Deduplicate by ID and ensure strictly sorted by time ASC (oldest at index 0).
      final uniqueMsgs = <String, MessageEntity>{};
      for (var m in msgs) {
        uniqueMsgs[m.id] = m;
      }
      final deduped = uniqueMsgs.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      state = state.copyWith(messages: deduped, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Sends [text] and appends the confirmed server message to the list.
/// No optimistic updates. No GET refresh after POST.
  /// Returns `true` on success, `false` on failure.
  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    state = state.copyWith(isSending: true, clearError: true);
    try {
      final confirmed = await _repo.sendMessage(_gameId, trimmed);

      // Deduplicate by ID and APPEND to the bottom
      final current = List<MessageEntity>.from(state.messages);
      if (!current.any((m) => m.id == confirmed.id)) {
        current.add(confirmed);
        // Resort to ensure chronological order doesn't break
        current.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }

      state = state.copyWith(messages: current, isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Appends an incoming real-time message (e.g. from Socket.IO).
/// Skips the message if:
  ///   (a) it came from the current user (already in the list from POST response)
  ///   (b) a message with the same ID already exists
  void appendIncoming(MessageEntity msg, String currentUserId) {
    if (msg.isMe(currentUserId)) return;

    final current = List<MessageEntity>.from(state.messages);
    if (current.any((m) => m.id == msg.id)) return; // already present

    // Append to bottom and ensure sorted order
    current.add(msg);
    current.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    state = state.copyWith(messages: current);
  }

  /// Clears the error banner.
  void clearError() => state = state.copyWith(clearError: true);
}

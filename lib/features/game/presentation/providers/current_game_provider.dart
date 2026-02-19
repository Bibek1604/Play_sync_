import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/features/game/domain/repositories/game_repository.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

/// Current Game State
class CurrentGameState {
  final Game? game;
  final List<ChatMessage> chatMessages;
  final bool isLoading;
  final String? error;
  final bool isSendingMessage;

  CurrentGameState({
    this.game,
    this.chatMessages = const [],
    this.isLoading = false,
    this.error,
    this.isSendingMessage = false,
  });

  CurrentGameState copyWith({
    Game? game,
    List<ChatMessage>? chatMessages,
    bool? isLoading,
    String? error,
    bool? isSendingMessage,
  }) {
    return CurrentGameState(
      game: game ?? this.game,
      chatMessages: chatMessages ?? this.chatMessages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}

/// Current Game Notifier
class CurrentGameNotifier extends StateNotifier<CurrentGameState> {
  final GameRepository _repository;
  StreamSubscription<Game>? _gameSubscription;
  StreamSubscription<ChatMessage>? _chatSubscription;

  CurrentGameNotifier(this._repository) : super(CurrentGameState());

  /// Join a game
  Future<void> joinGame(String gameId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final game = await _repository.joinGame(gameId);
      state = state.copyWith(
        game: game,
        isLoading: false,
      );

      // Start watching game updates
      _watchGame(gameId);
      
      // Load chat messages
      await _loadChatMessages(gameId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create and join a game
  Future<void> createGame({
    required String title,
    required String description,
    required List<String> tags,
    required int maxPlayers,
    required DateTime endTime,
    XFile? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final game = await _repository.createGame(
        title: title,
        description: description,
        tags: tags,
        maxPlayers: maxPlayers,
        endTime: endTime,
        imageFile: imageFile,
      );
      
      state = state.copyWith(
        game: game,
        isLoading: false,
      );

      // Start watching game updates
      _watchGame(game.id);
      
      // Initialize empty chat
      state = state.copyWith(chatMessages: []);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Leave current game
  Future<void> leaveGame() async {
    if (state.game == null) return;

    try {
      await _repository.leaveGame(state.game!.id);
      _cancelSubscriptions();
      state = CurrentGameState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Send chat message
  Future<void> sendMessage(String message) async {
    if (state.game == null) return;

    state = state.copyWith(isSendingMessage: true);

    try {
      final chatMessage = await _repository.sendChatMessage(
        state.game!.id,
        message,
      );

      // Add message to list if not already present
      final messages = List<ChatMessage>.from(state.chatMessages);
      if (!messages.any((m) => m.id == chatMessage.id)) {
        messages.add(chatMessage);
        state = state.copyWith(
          chatMessages: messages,
          isSendingMessage: false,
        );
      } else {
        state = state.copyWith(isSendingMessage: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSendingMessage: false,
        error: e.toString(),
      );
    }
  }

  /// Load chat messages
  Future<void> _loadChatMessages(String gameId) async {
    try {
      final messages = await _repository.getChatMessages(gameId);
      state = state.copyWith(chatMessages: messages);
      
      // Watch for new chat messages
      _watchChatMessages(gameId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Watch game updates via WebSocket
  void _watchGame(String gameId) {
    _gameSubscription = _repository.watchGame(gameId).listen(
      (game) {
        state = state.copyWith(game: game);
      },
      onError: (error) {
        // Handle error if needed
      },
    );
  }

  /// Watch chat messages via WebSocket
  void _watchChatMessages(String gameId) {
    _chatSubscription = _repository.watchChatMessages(gameId).listen(
      (message) {
        final messages = List<ChatMessage>.from(state.chatMessages);
        if (!messages.any((m) => m.id == message.id)) {
          messages.add(message);
          state = state.copyWith(chatMessages: messages);
        }
      },
      onError: (error) {
        // Handle error if needed
      },
    );
  }

  /// Cancel subscriptions
  void _cancelSubscriptions() {
    _gameSubscription?.cancel();
    _chatSubscription?.cancel();
    _gameSubscription = null;
    _chatSubscription = null;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

/// Current Game Provider
final currentGameProvider =
    StateNotifierProvider<CurrentGameNotifier, CurrentGameState>((ref) {
  return CurrentGameNotifier(
    ref.watch(gameRepositoryProvider),
  );
});

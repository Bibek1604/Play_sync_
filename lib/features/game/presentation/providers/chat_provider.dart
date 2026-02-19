import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/core/api/api_endpoints.dart';
import 'package:play_sync_new/core/services/socket_service.dart';
import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/features/game/domain/usecases/get_chat_messages.dart';
import 'package:play_sync_new/features/game/domain/usecases/send_chat_message.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';

/// Chat State
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Chat Notifier
/// 
/// Manages chat state for a specific game
/// Handles socket subscriptions and message sending
class ChatNotifier extends StateNotifier<ChatState> {
  final String gameId;
  final GetChatMessages _getChatMessages;
  final SendChatMessage _sendChatMessage;
  final SocketService _socketService;
  
  StreamSubscription? _socketSubscription;

  ChatNotifier({
    required this.gameId,
    required GetChatMessages getChatMessages,
    required SendChatMessage sendChatMessage,
    required SocketService socketService,
  })  : _getChatMessages = getChatMessages,
        _sendChatMessage = sendChatMessage,
        _socketService = socketService,
        super(ChatState()) {
    _init();
  }

  void _init() {
    loadMessages();
    _subscribeToSocket();
  }

  /// Load initial messages
  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _getChatMessages(gameId);
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Subscribe to socket events
  void _subscribeToSocket() {
    // Join the game socket room using correct backend format (gameId as plain string)
    _socketService.emitWithAck(ApiEndpoints.socketJoinGame, gameId);

    // Listen for new chat messages from backend ('chat:message')
    _socketService.on(ApiEndpoints.socketChatMessage, _onNewMessage);
  }

  /// Handle incoming socket message
  void _onNewMessage(dynamic data) {
    if (data == null || data is! Map) return;

    try {
      final msgGameId = data['gameId']?.toString() ?? gameId;
      // Only handle messages for this game
      if (msgGameId != gameId) return;

      final msgId = data['id']?.toString() ?? data['_id']?.toString() ?? '';

      // Deduplication: skip if we already have a message with this id
      if (msgId.isNotEmpty && state.messages.any((m) => m.id == msgId)) return;

      // Sender info may be nested under 'sender' object (backend populates it)
      final sender = data['sender'] is Map ? data['sender'] as Map : null;
      final isSystem = data['type']?.toString() == 'SYSTEM' ||
          (data['isSystemMessage'] == true);

      final message = ChatMessage(
        id: msgId.isNotEmpty ? msgId : DateTime.now().millisecondsSinceEpoch.toString(),
        gameId: msgGameId,
        message: data['content']?.toString() ?? data['message']?.toString() ?? '',
        senderId: sender?['id']?.toString() ?? sender?['_id']?.toString() ?? data['senderId']?.toString() ?? '',
        senderName: sender?['fullName']?.toString() ?? sender?['name']?.toString() ?? data['senderName']?.toString() ?? 'Unknown',
        senderAvatar: sender?['profilePicture']?.toString() ?? sender?['avatar']?.toString(),
        timestamp: data['createdAt'] != null
            ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        type: isSystem ? MessageType.system : MessageType.user,
      );

      state = state.copyWith(
        messages: [message, ...state.messages],
      );
    } catch (e) {
      print('Error parsing socket message: $e');
    }
  }

  /// Send a message via socket (chat:send)
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(isSending: true, error: null);
    try {
      // Use socket emit for real-time delivery (backend broadcasts back via chat:message)
      // The socket event 'chat:message' will be received and handled by _onNewMessage
      // which has deduplication built-in, so no double-add.
      _socketService.emitWithAck(
        ApiEndpoints.socketChatSend,
        {'gameId': gameId, 'content': content.trim()},
      );

      state = state.copyWith(isSending: false);
    } catch (e) {
      // Fallback to HTTP if socket fails
      try {
        final message = await _sendChatMessage(gameId, content);
        // Only add if no socket echo already arrived
        if (!state.messages.any((m) => m.id == message.id)) {
          state = state.copyWith(
            messages: [message, ...state.messages],
          );
        }
        state = state.copyWith(isSending: false);
      } catch (httpError) {
        state = state.copyWith(
          isSending: false,
          error: httpError.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    // Leave game socket room
    _socketService.emitWithAck(ApiEndpoints.socketLeaveGame, gameId);
    _socketService.off(ApiEndpoints.socketChatMessage, _onNewMessage);
    _socketSubscription?.cancel();
    super.dispose();
  }
}

/// Chat Provider (Family)
/// 
/// Usage: ref.watch(chatProvider(gameId))
final chatProvider = StateNotifierProvider.family.autoDispose<ChatNotifier, ChatState, String>((ref, gameId) {
  return ChatNotifier(
    gameId: gameId,
    getChatMessages: ref.watch(getChatMessagesUseCaseProvider),
    sendChatMessage: ref.watch(sendChatMessageUseCaseProvider),
    socketService: ref.watch(socketServiceProvider),
  );
});

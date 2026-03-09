import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/secure_storage_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';
class ChatState extends Equatable {
  final List<ChatRoom> rooms;
  final Map<String, List<ChatMessage>> messagesByRoom;
  final String? activeRoomId;
  final bool isSending;
  final bool isLoadingRooms;
  final bool isLoadingMessages;
  final bool isLoadingMore;
  final bool hasMore;
  final String? nextCursor;
  final String? error;

  const ChatState({
    this.rooms = const [],
    this.messagesByRoom = const {},
    this.activeRoomId,
    this.isSending = false,
    this.isLoadingRooms = false,
    this.isLoadingMessages = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.nextCursor,
    this.error,
  });

  List<ChatMessage> get activeMessages =>
      activeRoomId != null ? (messagesByRoom[activeRoomId] ?? []) : [];

  ChatRoom? get activeRoom =>
      activeRoomId != null
          ? rooms.firstWhere((r) => r.id == activeRoomId,
              orElse: () => ChatRoom(id: activeRoomId!, name: 'Chat'))
          : null;

  ChatState copyWith({
    List<ChatRoom>? rooms,
    Map<String, List<ChatMessage>>? messagesByRoom,
    String? activeRoomId,
    bool? isSending,
    bool? isLoadingRooms,
    bool? isLoadingMessages,
    bool? isLoadingMore,
    bool? hasMore,
    String? nextCursor,
    String? error,
    bool clearError = false,
    bool clearRoom = false,
    bool clearCursor = false,
  }) {
    return ChatState(
      rooms: rooms ?? this.rooms,
      messagesByRoom: messagesByRoom ?? this.messagesByRoom,
      activeRoomId: clearRoom ? null : (activeRoomId ?? this.activeRoomId),
      isSending: isSending ?? this.isSending,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        rooms,
        messagesByRoom,
        activeRoomId,
        isSending,
        isLoadingRooms,
        isLoadingMessages,
        isLoadingMore,
        hasMore,
        nextCursor,
        error
      ];
}
/// Chat notifier for the Messages tab (REST-only implementation).
/// Messages use the existing game-chat REST endpoints — **no Socket.IO**:
///   GET  /api/v1/games/:gameId/chat  (fetch history)
///   POST /api/v1/games/:gameId/chat  (send message)
/// Architecture:
/// - Messages are sent via REST and only added to state after server response
/// - No optimistic updates, no temporary message IDs
/// - No Socket.IO real-time — chat is request-response only
/// - Clean REST-based state management with no deduplication complexity
class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _api;
  final ChatRepository _chatRepo;
  String _myId;
  final FlutterSecureStorage _storage;

  ChatNotifier(this._api, this._chatRepo, this._myId, this._storage) : super(const ChatState()) {
    _resolveMyId();
    fetchRooms();
  }

  /// Ensure _myId is populated — falls back to secure storage if auth providers
  /// hadn't loaded yet when the provider was constructed.
  Future<void> _resolveMyId() async {
    if (_myId.isNotEmpty) return;
    final id = (await _storage.read(key: 'user_id') ?? '').trim();
    if (id.isNotEmpty) _myId = id;
  }
/// Build room list from user's joined + created games (existing endpoints).
  Future<void> fetchRooms() async {
    state = state.copyWith(isLoadingRooms: true, clearError: true);
    try {
      final results = await Future.wait([
        _api.get(ApiEndpoints.getMyJoinedGames),
        _api.get(ApiEndpoints.getMyCreatedGames),
      ]);

      final seen = <String>{};
      final rooms = <ChatRoom>[];

      for (final resp in results) {
        final raw = resp.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          final inner = raw['data'];
          if (inner is List) {
            list = inner;
          } else if (inner is Map) {
            list = (inner['games'] as List?) ?? (inner['data'] as List?) ?? [];
          }
        }
        for (final item in list) {
          final j = item as Map<String, dynamic>;
          final id = j['_id'] as String? ?? j['id'] as String? ?? '';
          if (id.isEmpty || !seen.add(id)) continue;
          rooms.add(ChatRoom(
            id: id,
            name: j['title'] as String? ?? 'Game Chat',
            avatarUrl: j['imageUrl'] as String? ?? j['image'] as String?,
            lastMessage: j['lastMessage'] as String?,
            isGroupChat: true,
          ));
        }
      }

      state = state.copyWith(rooms: rooms, isLoadingRooms: false);
    } catch (_) {
      state = state.copyWith(isLoadingRooms: false);
    }
  }
Future<void> openRoom(String roomId) async {
    state = state.copyWith(activeRoomId: roomId, isLoadingMessages: true);
    await _loadMessages(roomId);
    // No socket connection — we use REST only
  }

  void closeRoom() {
    state = state.copyWith(clearRoom: true);
  }

  /// Called when the user leaves a game from GameChatPage.
  /// Removes the room and its messages from the chat section.
  void leaveRoom(String gameId) {
    final updatedRooms = state.rooms.where((r) => r.id != gameId).toList();
    final updatedMessages =
        Map<String, List<ChatMessage>>.from(state.messagesByRoom)
          ..remove(gameId);
    state = state.copyWith(
      rooms: updatedRooms,
      messagesByRoom: updatedMessages,
      clearRoom: state.activeRoomId == gameId,
    );
  }

  Future<void> _loadMessages(String roomId) async {
    try {
      final result = await _chatRepo.getChatHistory(roomId);

      final msgs = <ChatMessage>[];
      // API returns newest-first; reverse so oldest appears at top
      for (final msg in result.messages.reversed) {
        msgs.add(msg);
      }

      final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
        ..[roomId] = msgs;
      state = state.copyWith(
        messagesByRoom: updated,
        isLoadingMessages: false,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMessages: false);
    }
  }

  /// Loads older messages for the active room (pagination).
  /// Call this when the user scrolls to the top of the chat.
  Future<void> loadMoreMessages() async {
    final roomId = state.activeRoomId;
    if (roomId == null || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _chatRepo.getChatHistory(
        roomId,
        before: state.nextCursor,
      );

      final current = List<ChatMessage>.from(state.messagesByRoom[roomId] ?? []);
      final currentIds = current.map((m) => m.id).toSet();
      
      final older = <ChatMessage>[];
      for (final msg in result.messages.reversed) {
        // Skip if message already in current list (prevent duplicates on pagination boundary)
        if (!currentIds.contains(msg.id)) {
          older.add(msg);
        }
      }

      current.insertAll(0, older);

      final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
        ..[roomId] = current;
      state = state.copyWith(
        messagesByRoom: updated,
        isLoadingMore: false,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
/// Sends a message via REST API.
  /// **Only** adds the message to local state after receiving server response.
  /// No optimistic updates, no temporary IDs, no deduplication complexity.
  Future<void> sendMessage(String content) async {
    final roomId = state.activeRoomId;
    if (roomId == null || content.trim().isEmpty) return;

    final trimmed = content.trim();
    state = state.copyWith(isSending: true, clearError: true);

    try {
      // Send message and wait for server response
      final confirmedMessage = await _chatRepo.sendMessage(roomId, trimmed);
      
      if (!mounted) return;
      
      // Add the server-returned message (this is the single source of truth)
      _appendMessage(roomId, confirmedMessage);
      state = state.copyWith(isSending: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isSending: false, 
        error: 'Failed to send message: ${e.toString()}',
      );
    }
  }

  void _appendMessage(String roomId, ChatMessage msg) {
    final current = List<ChatMessage>.from(state.messagesByRoom[roomId] ?? []);
    current.removeWhere((m) => m.id == msg.id);
    current.add(msg);
    final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
      ..[roomId] = current;
    state = state.copyWith(messagesByRoom: updated);
  }

  /// Parses backend ChatMessageDTO
  /// Handles both old format (nested user object) and new format (flat senderId/text)
  ChatMessage _parseDTO(Map<String, dynamic> json, String roomId) {
    // Try new format first (senderId field)
    final newFormatSenderId = json['senderId'] as String?;
    
    if (newFormatSenderId != null && newFormatSenderId.isNotEmpty) {
      // New REST API format: senderId, senderName, text
      final senderId = (newFormatSenderId).trim();
      final senderName = (json['senderName'] as String?)?.trim() ?? 'Unknown';
      final senderAvatar = (json['senderAvatar'] as String?)?.trim();
      final type = json['type'] as String? ?? 'text';
      final isSystem = type == 'system';
      final msgId = (json['_id'] as String? ?? json['id'] as String? ?? '').trim();

      return ChatMessage(
        id: msgId.isNotEmpty ? msgId : 'msg_${DateTime.now().microsecondsSinceEpoch}',
        roomId: roomId,
        senderId: isSystem ? 'system' : senderId,
        senderName: isSystem ? 'System' : (senderName.isNotEmpty ? senderName : 'Unknown'),
        senderAvatar: senderAvatar?.isNotEmpty == true ? senderAvatar : null,
        content: json['text'] as String? ?? '',
        type: isSystem ? MessageType.system : MessageType.text,
        sentAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
    }
    
    // Fallback: Old backend format with nested user object
    final rawUser = json['user'];
    String senderId = '';
    String senderName = 'Unknown';
    String? senderAvatar;

    if (rawUser is Map<String, dynamic>) {
      senderId = (rawUser['_id'] as String? ?? rawUser['id'] as String? ?? '').trim();
      final fullName = (rawUser['fullName'] as String?)?.trim() ?? '';
      final username = (rawUser['username'] as String?)?.trim() ?? '';
      senderName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : 'Unknown');
      senderAvatar = rawUser['profilePicture'] as String?;
    } else if (rawUser != null) {
      senderId = rawUser.toString().trim();
    }

    final type = json['type'] as String? ?? 'text';
    final isSystem = type == 'system';
    final msgId = (json['_id'] as String? ?? json['id'] as String? ?? '').trim();

    return ChatMessage(
      id: msgId.isNotEmpty ? msgId : 'msg_${DateTime.now().microsecondsSinceEpoch}',
      roomId: roomId,
      senderId: isSystem ? 'system' : senderId,
      senderName: isSystem ? 'System' : senderName,
      senderAvatar: senderAvatar,
      content: json['content'] as String? ?? '',
      type: isSystem ? MessageType.system : MessageType.text,
      sentAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isRead: true,
    );
  }
@override
  void dispose() {
    super.dispose();
  }
}
/// Repository provider for chat data operations (clean architecture).
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return ChatRepository(api);
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final api = ref.watch(apiClientProvider);
  final chatRepo = ref.watch(chatRepositoryProvider);
  final auth = ref.watch(authNotifierProvider);
  final vm = ref.watch(authViewModelProvider);
  final myId = (auth.user?.userId ?? vm.user?.userId ?? '').trim();
  final storage = ref.watch(secureStorageProvider);
  return ChatNotifier(api, chatRepo, myId, storage);
});

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/secure_storage_provider.dart';
import '../../../../../core/services/socket_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';

// ─── State ───────────────────────────────────────────────────────────────────

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

// ─── Notifier ────────────────────────────────────────────────────────────────

/// Chat notifier for the Messages tab.
///
/// Rooms are built from the user's joined/created games via existing endpoints.
/// Messages use the existing game-chat routes — no new backend routes needed:
///   GET  /games/:gameId/chat  (history)
///   POST /games/:gameId/chat  (REST fallback send)
///
/// Real-time uses the **same** Socket.IO events as GameChatPage:
///   Emit:   join:game  gameId
///           leave:game gameId
///           chat:send  { gameId, content }  (with ack)
///   Listen: chat:message  <ChatMessageDTO>
class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _api;
  final ChatRepository _chatRepo;
  String _myId;
  final FlutterSecureStorage _storage;

  io.Socket? _socket;
  String? _socketRoomId;

  // Dedup & optimistic-send tracking (mirrors GameChatPage)
  final Set<String> _seenMsgIds = {};
  final Set<String> _pendingTempIds = {};

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

  // ── Rooms ─────────────────────────────────────────────────────────────────

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

  // ── Open / close room ─────────────────────────────────────────────────────

  Future<void> openRoom(String roomId) async {
    state = state.copyWith(activeRoomId: roomId, isLoadingMessages: true);
    await _loadMessages(roomId);
    await _connectSocket(roomId);
  }

  void closeRoom() {
    _disconnectSocket();
    state = state.copyWith(clearRoom: true);
  }

  /// Called when the user leaves a game from GameChatPage.
  /// Removes the room and its messages from the chat section.
  void leaveRoom(String gameId) {
    if (state.activeRoomId == gameId) {
      _disconnectSocket();
    }
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

      _seenMsgIds.clear();
      final msgs = <ChatMessage>[];
      // API returns newest-first; reverse so oldest appears at top
      for (final msg in result.messages.reversed) {
        if (msg.id.isNotEmpty) _seenMsgIds.add(msg.id);
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

      final older = <ChatMessage>[];
      for (final msg in result.messages.reversed) {
        if (msg.id.isNotEmpty && !_seenMsgIds.add(msg.id)) continue; // skip dups
        older.add(msg);
      }

      final current = List<ChatMessage>.from(state.messagesByRoom[roomId] ?? []);
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

  // ── Socket (same events as GameChatPage) ─────────────────────────────────

  Future<void> _connectSocket(String roomId) async {
    _disconnectSocket();
    final token = await _storage.read(key: 'access_token') ?? '';
    if (token.isEmpty) return;

    _socketRoomId = roomId;
    _socket = SocketService.instance.getSocket(token: token);

    if (_socket!.connected) {
      _socket!.emit('join:game', roomId);
    }

    _socket!
      ..on('connect', (_) {
        if (!mounted) return;
        _socket!.emit('join:game', roomId);
      })
      ..on('disconnect', (_) {
        if (!mounted) return;
      })
      ..on('chat:message', (data) {
        if (!mounted) return;
        final raw = data as Map<String, dynamic>;

        // Only handle messages for the active room
        final gameId = (raw['gameId'] as String? ?? '').trim();
        if (gameId.isNotEmpty && gameId != roomId) return;

        // Dedup
        final msgId = (raw['_id'] as String? ?? '').trim();
        if (msgId.isNotEmpty && !_seenMsgIds.add(msgId)) return;

        final msg = _parseDTO(raw, roomId);

        // Robust isMe check
        final isMe = _myId.isNotEmpty && (
          msg.senderId.trim() == _myId.trim() || 
          msg.senderName.trim().toLowerCase() == 'me' ||
          msg.senderName.trim().toLowerCase() == 'you'
        );

        if (isMe) {
          final msgs = List<ChatMessage>.from(state.messagesByRoom[roomId] ?? []);
          // Replace matching temp message
          final idx = msgs.indexWhere(
              (m) => m.id.startsWith('tmp_') && _pendingTempIds.contains(m.id));
          
          if (idx != -1) {
            final oldId = msgs[idx].id;
            _pendingTempIds.remove(oldId);
            msgs[idx] = msg;
            final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
              ..[roomId] = msgs;
            state = state.copyWith(messagesByRoom: updated);
            _seenMsgIds.add(msg.id);
            debugPrint('[Chat] Deduplicated: Replaced temp $oldId with $msgId');
            return;
          }
        }

        // Dupe guard: skip if already loaded correctly
        final exists = (state.messagesByRoom[roomId] ?? []).any((m) => m.id == msg.id);
        if (exists && msg.id.isNotEmpty) return;

        _appendMessage(roomId, msg);
      });
  }

  void _disconnectSocket() {
    if (_socket != null && _socketRoomId != null) {
      _socket!.emit('leave:game', _socketRoomId);
      _socket!.off('chat:message');
      _socket!.off('connect');
      _socket!.off('disconnect');
    }
    _socket = null;
    _socketRoomId = null;
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    final roomId = state.activeRoomId;
    if (roomId == null || content.trim().isEmpty) return;

    final trimmed = content.trim();
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';

    final optimistic = ChatMessage(
      id: tempId,
      roomId: roomId,
      senderId: _myId.isNotEmpty ? _myId : 'me',
      senderName: 'Me',
      content: trimmed,
      sentAt: DateTime.now(),
    );

    _pendingTempIds.add(tempId);
    _appendMessage(roomId, optimistic);
    state = state.copyWith(isSending: true);

    try {
      if (_socket != null && _socket!.connected) {
        _socket!.emitWithAck(
          'chat:send',
          {'gameId': roomId, 'content': trimmed},
          ack: (ack) {
            if (!mounted) return;
            final ackMap = (ack as Map<String, dynamic>?) ?? {};
            if (ackMap['success'] != true) _pendingTempIds.remove(tempId);
          },
        );
      } else {
        // API fallback
        try {
          final confirmed = await _chatRepo.sendMessage(roomId, trimmed);
          final msgs = List<ChatMessage>.from(state.messagesByRoom[roomId] ?? []);
          final idx = msgs.indexWhere((m) => m.id == tempId);
          if (idx != -1) msgs[idx] = confirmed;
          final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
            ..[roomId] = msgs;
          state = state.copyWith(messagesByRoom: updated);
          _pendingTempIds.remove(tempId);
        } catch (_) {
          _pendingTempIds.remove(tempId);
        }
      }
    } catch (_) {
      _pendingTempIds.remove(tempId);
    } finally {
      if (mounted) state = state.copyWith(isSending: false);
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

  /// Parses backend ChatMessageDTO (same shape used by game chat).
  /// Shape: { _id, user: { _id, username, fullName, profilePicture }, content, type, createdAt }
  ChatMessage _parseDTO(Map<String, dynamic> json, String roomId) {
    final rawUser = json['user'];
    String senderId = '';
    String senderName = 'User';
    String? senderAvatar;

    if (rawUser is Map<String, dynamic>) {
      senderId = (rawUser['_id'] as String? ?? rawUser['id'] as String? ?? '').trim();
      senderName = rawUser['fullName'] as String? ?? rawUser['username'] as String? ?? 'User';
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

  // ── Mock data (shown if game list unavailable) ─────────────────────────────

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

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

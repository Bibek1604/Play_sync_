import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../../domain/entities/chat_message.dart';
import '../../../../../core/api/api_endpoints.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ChatState extends Equatable {
  final List<ChatRoom> rooms;
  final Map<String, List<ChatMessage>> messagesByRoom;
  final String? activeRoomId;
  final bool isConnected;
  final bool isSending;
  final bool isLoadingRooms;
  final String? error;

  const ChatState({
    this.rooms = const [],
    this.messagesByRoom = const {},
    this.activeRoomId,
    this.isConnected = false,
    this.isSending = false,
    this.isLoadingRooms = false,
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
    bool? isConnected,
    bool? isSending,
    bool? isLoadingRooms,
    String? error,
    bool clearError = false,
    bool clearRoom = false,
  }) {
    return ChatState(
      rooms: rooms ?? this.rooms,
      messagesByRoom: messagesByRoom ?? this.messagesByRoom,
      activeRoomId: clearRoom ? null : (activeRoomId ?? this.activeRoomId),
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [rooms, messagesByRoom, activeRoomId, isConnected, isSending, isLoadingRooms, error];
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _dio;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;

  ChatNotifier(this._dio) : super(const ChatState()) {
    fetchRooms();
  }

  // ── Room loading ──────────────────────────────────────────────────────────

  Future<void> fetchRooms() async {
    state = state.copyWith(isLoadingRooms: true, clearError: true);
    try {
      final resp = await _dio.get('${ApiEndpoints.baseUrl}/chat/rooms');
      final list = (resp.data as List? ?? [])
          .map((j) => ChatRoom.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(rooms: list, isLoadingRooms: false);
    } on DioException {
      // Demo rooms when offline
      state = state.copyWith(rooms: _mockRooms(), isLoadingRooms: false);
    }
  }

  // ── Room selection + WebSocket ────────────────────────────────────────────

  Future<void> openRoom(String roomId) async {
    state = state.copyWith(activeRoomId: roomId);
    await _loadMessages(roomId);
    _connectWebSocket(roomId);
  }

  void closeRoom() {
    _disconnect();
    state = state.copyWith(clearRoom: true);
  }

  Future<void> _loadMessages(String roomId) async {
    try {
      final resp = await _dio.get('${ApiEndpoints.baseUrl}/chat/rooms/$roomId/messages');
      final list = (resp.data as List? ?? [])
          .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
          .toList();
      final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
        ..[roomId] = list;
      state = state.copyWith(messagesByRoom: updated);
    } on DioException {
      // Use existing or empty
      if (!state.messagesByRoom.containsKey(roomId)) {
        final updated = Map<String, List<ChatMessage>>.from(state.messagesByRoom)
          ..[roomId] = _mockMessages(roomId);
        state = state.copyWith(messagesByRoom: updated);
      }
    }
  }

  void _connectWebSocket(String roomId) {
    _disconnect();
    try {
      final wsUrl = ApiEndpoints.baseUrl.replaceFirst('http', 'ws');
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/chat/ws/$roomId'));
      state = state.copyWith(isConnected: true);

      _wsSub = _channel!.stream.listen(
        (raw) {
          final data = jsonDecode(raw as String) as Map<String, dynamic>;
          final msg = ChatMessage.fromJson(data);
          _appendMessage(msg.roomId, msg);
        },
        onError: (_) => state = state.copyWith(isConnected: false),
        onDone: () => state = state.copyWith(isConnected: false),
      );
    } catch (_) {
      state = state.copyWith(isConnected: false);
    }
  }

  void _disconnect() {
    _wsSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _wsSub = null;
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    final roomId = state.activeRoomId;
    if (roomId == null || content.trim().isEmpty) return;

    final optimistic = ChatMessage(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      senderId: 'me',
      senderName: 'Me',
      content: content.trim(),
      sentAt: DateTime.now(),
      isFromMe: true,
    );
    _appendMessage(roomId, optimistic);
    state = state.copyWith(isSending: true);

    try {
      if (_channel != null && state.isConnected) {
        _channel!.sink.add(jsonEncode({'type': 'message', 'content': content.trim()}));
      } else {
        await _dio.post(
          '${ApiEndpoints.baseUrl}/chat/rooms/$roomId/messages',
          data: {'content': content.trim()},
        );
      }
      state = state.copyWith(isSending: false);
    } on DioException {
      // Optimistic msg stays for demo
      state = state.copyWith(isSending: false);
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

  // ── Mock data ─────────────────────────────────────────────────────────────

  List<ChatRoom> _mockRooms() => [
    const ChatRoom(id: 'r1', name: 'Weekend Football', lastMessage: 'Who is coming?', isGroupChat: true, unreadCount: 3),
    const ChatRoom(id: 'r2', name: 'Chess Club', lastMessage: 'GG everyone!', isGroupChat: true, unreadCount: 0),
    const ChatRoom(id: 'r3', name: 'Alex', lastMessage: 'See you tomorrow', isGroupChat: false, unreadCount: 1),
    const ChatRoom(id: 'r4', name: 'Game Night Crew', lastMessage: 'Ready at 9pm?', isGroupChat: true, unreadCount: 5),
  ];

  List<ChatMessage> _mockMessages(String roomId) => [
    ChatMessage(id: 'm1', roomId: roomId, senderId: 'u1', senderName: 'Alex', content: 'Hey everyone! Ready for the game?', sentAt: DateTime.now().subtract(const Duration(minutes: 30))),
    ChatMessage(id: 'm2', roomId: roomId, senderId: 'u2', senderName: 'Jordan', content: "Absolutely! Can't wait 🔥", sentAt: DateTime.now().subtract(const Duration(minutes: 28))),
    ChatMessage(id: 'm3', roomId: roomId, senderId: 'u3', senderName: 'Sam', content: 'I might be 10 mins late', sentAt: DateTime.now().subtract(const Duration(minutes: 20))),
    ChatMessage(id: 'm4', roomId: roomId, senderId: 'me', senderName: 'Me', content: "No worries, we'll warm up!", sentAt: DateTime.now().subtract(const Duration(minutes: 15)), isFromMe: true),
    ChatMessage(id: 'm5', roomId: roomId, senderId: 'u1', senderName: 'Alex', content: 'See you all there 👋', sentAt: DateTime.now().subtract(const Duration(minutes: 5))),
  ];

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final _chatDioProvider = Provider<Dio>((ref) => Dio());

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.watch(_chatDioProvider)),
);

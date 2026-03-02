import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../../../../core/services/socket_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';

/// Real-time chat page for a specific game room.
///
/// Socket events (backend contract):
///   Emit:   join:game  → gameId (String)
///           leave:game → gameId (String)
///           chat:send  → {gameId, content}  (with ack callback)
///   Listen: chat:message → ChatMessageDTO
///
/// REST: GET /games/:gameId/chat  → {data: {messages: [], hasMore, nextCursor}}
class GameChatPage extends ConsumerStatefulWidget {
  const GameChatPage({super.key, required this.gameId, required this.gameTitle});

  final String gameId;
  final String gameTitle;

  @override
  ConsumerState<GameChatPage> createState() => _GameChatPageState();
}

class _GameChatPageState extends ConsumerState<GameChatPage> {
  final _scrollController = ScrollController();
  final _messageController = TextEditingController();

  io.Socket? _socket;
  final List<_ChatMsg> _messages = [];
  /// Tracks server-assigned message IDs to prevent duplicates from:
  ///   (a) history load + socket echo, (b) own message echo when _myId mismatch.
  final Set<String> _seenMsgIds = <String>{};
  bool _isConnected = false;
  bool _isLoadingHistory = true;
  String _myId = '';

  @override
  void initState() {
    super.initState();
    // Use authNotifierProvider (primary) then fall back to authViewModelProvider.
    // Both are checked because different parts of the app initialise them at
    // different times; we need _myId before the first socket message arrives.
    _myId = ref.read(authNotifierProvider).user?.userId ??
        ref.read(authViewModelProvider).user?.userId ??
        '';
    _loadHistory();
    _initSocket();
  }

  // ── History ──────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/games/${widget.gameId}/chat');
      final body = resp.data as Map<String, dynamic>;
      // API response: { success, message, data: { messages: [...], hasMore, nextCursor } }
      final inner = body['data'] as Map<String, dynamic>?;
      final rawList = (inner?['messages'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _seenMsgIds.clear();
        // API returns newest-first; reverse so oldest appears at top
        for (final raw in rawList.reversed) {
          final map = raw as Map<String, dynamic>;
          // Register ID so the socket echo of history messages is ignored.
          final id = map['_id'] as String? ?? '';
          if (id.isNotEmpty) _seenMsgIds.add(id);
          _messages.add(_parseDTO(map));
        }
        _isLoadingHistory = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // ── Socket ───────────────────────────────────────────────────────────────

  Future<void> _initSocket() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token') ?? '';
    if (token.isEmpty) return;

    _socket = SocketService.instance.getSocket(token: token);

    // If already connected, join immediately
    if (_socket!.connected) {
      if (mounted) setState(() => _isConnected = true);
      _socket!.emit('join:game', widget.gameId);
    }

    _socket!
      ..on('connect', (_) {
        if (!mounted) return;
        setState(() => _isConnected = true);
        _socket!.emit('join:game', widget.gameId);
      })
      ..on('disconnect', (_) {
        if (!mounted) return;
        setState(() => _isConnected = false);
      })
      ..on('chat:message', (data) {
        if (!mounted) return;
        final raw = data as Map<String, dynamic>;

        // ── Deduplication: ID-based ──────────────────────────────────────
        // Prevents adding a message that was already loaded from REST history
        // or that the socket echoed back after we sent it optimistically.
        final msgId = raw['_id'] as String? ?? '';
        if (msgId.isNotEmpty && !_seenMsgIds.add(msgId)) return;

        final msg = _parseDTO(raw);

        // ── Own-echo guard ───────────────────────────────────────────────
        // The backend broadcasts to ALL clients in the room, including the
        // sender.  We already showed an optimistic bubble, so skip echoes
        // of our own messages.  The ID-dedup above handles this when _myId
        // is set correctly; this is a secondary safety net.
        if (msg.isOwn) return;

        setState(() => _messages.add(msg));
        _scrollToBottom();
      });
  }

  // ── Message parsing ───────────────────────────────────────────────────────

  /// Parses a backend ChatMessageDTO into a local [_ChatMsg].
  ///
  /// Backend shape:
  /// ```json
  /// {
  ///   "_id": "...",
  ///   "user": { "_id": "...", "username": "...", "fullName": "..." } | null,
  ///   "content": "...",
  ///   "type": "text" | "system",
  ///   "createdAt": "<ISO string>"
  /// }
  /// ```
  _ChatMsg _parseDTO(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>?;
    final type = map['type'] as String? ?? 'text';
    final isSystem = type == 'system';
    final senderId = user?['_id'] as String? ?? '';
    final isOwn = !isSystem && _myId.isNotEmpty && senderId == _myId;

    return _ChatMsg(
      content: map['content'] as String? ?? '',
      senderName: isSystem
          ? 'System'
          : (user?['fullName'] as String? ??
              user?['username'] as String? ??
              'User'),
      senderId: senderId,
      timestamp:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      isOwn: isOwn,
      isSystem: isSystem,
    );
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _socket == null || !_isConnected) return;

    // Optimistic bubble shown immediately
    final optimistic = _ChatMsg(
      content: content,
      senderName: 'You',
      senderId: _myId,
      timestamp: DateTime.now(),
      isOwn: true,
    );
    setState(() => _messages.add(optimistic));
    _messageController.clear();
    _scrollToBottom();

    // Emit with server acknowledgment
    _socket!.emitWithAck(
      'chat:send',
      {'gameId': widget.gameId, 'content': content},
      ack: (data) {
        if (!mounted) return;
        // data can be null (no ack) or Map
        final ack = (data is Map) ? data as Map<String, dynamic> : null;
        if (ack != null && ack['success'] == false) {
          // Remove optimistic message on failure
          setState(() => _messages.remove(optimistic));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ack['error'] as String? ?? 'Failed to send'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    if (_socket != null) {
      _socket!.emit('leave:game', widget.gameId);
      _socket!.off('chat:message');
      _socket!.off('connect');
      _socket!.off('disconnect');
    }
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.gameTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _isConnected ? 'Connected' : 'Connecting…',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? AppColors.success : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _MessageBubble(msg: _messages[i]),
                      ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _isConnected
                            ? 'Type a message…'
                            : 'Connecting…',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surface,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isConnected ? _sendMessage : null,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _ChatMsg {
  const _ChatMsg({
    required this.content,
    required this.senderName,
    required this.senderId,
    required this.timestamp,
    required this.isOwn,
    this.isSystem = false,
  });
  final String content;
  final String senderName;
  final String senderId;
  final DateTime timestamp;
  final bool isOwn;
  final bool isSystem;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _ChatMsg msg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.content,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: msg.isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              msg.isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!msg.isOwn)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(msg.senderName,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.6))),
              ),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isOwn ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: msg.isOwn ? cs.onPrimary : cs.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

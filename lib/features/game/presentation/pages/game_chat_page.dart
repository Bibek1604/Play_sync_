import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../../../../core/services/socket_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';
import '../../domain/entities/game_entity.dart';

/// Real-time chat page for a specific game room.
///
/// Socket events (backend contract):
///   Emit:   join:game  → gameId (String)
///           leave:game → gameId (String)
///           chat:send  → {gameId, content}  (with ack callback)
///   Listen: chat:message → ChatMessageDTO
///
/// REST: GET /games/:gameId/chat  → {data: {messages: [], hasMore, nextCursor}}
/// REST fallback: POST /games/:gameId/chat → send message when socket offline
class GameChatPage extends ConsumerStatefulWidget {
  const GameChatPage({super.key, required this.game});

  final GameEntity game;

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
  /// Tracks temporary IDs for optimistic messages awaiting server confirmation.
  final Set<String> _pendingTempIds = <String>{};
  bool _isConnected = false;
  bool _isLoadingHistory = true;
  bool _isSendingViaRest = false;
  String _myId = '';
  static const int _maxMessages = 50; // Limit stored messages

  @override
  void initState() {
    super.initState();
    // Use authNotifierProvider (primary) then fall back to authViewModelProvider.
    // Both are checked because different parts of the app initialise them at
    // different times; we need _myId before the first socket message arrives.
    _myId = ref.read(authNotifierProvider).user?.userId ??
        ref.read(authViewModelProvider).user?.userId ??
        '';
    
    // Debug: Log user ID to verify it's set correctly
    if (_myId.isEmpty) {
      debugPrint('[CHAT] WARNING: _myId is empty - message alignment may fail');
    } else {
      debugPrint('[CHAT] Current user ID: $_myId');
    }
    
    _loadHistory();
    _initSocket();
  }

  // ── History ──────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/games/${widget.game.id}/chat');
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
        // Enforce message limit (keep last 50 messages)
        if (_messages.length > _maxMessages) {
          final toRemove = _messages.length - _maxMessages;
          _messages.removeRange(0, toRemove);
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
      _socket!.emit('join:game', widget.game.id);
    }

    _socket!
      ..on('connect', (_) {
        if (!mounted) return;
        setState(() => _isConnected = true);
        _socket!.emit('join:game', widget.game.id);
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
        if (msgId.isNotEmpty && !_seenMsgIds.add(msgId)) {
          debugPrint('[CHAT] Skipped duplicate message ID: $msgId');
          return;
        }

        final msg = _parseDTO(raw);

        // ── Own-message handling ─────────────────────────────────────────
        // If this is our own message, check if we have an optimistic version.
        if (msg.isOwn) {
          // Find and replace any pending temp message for this content
          final tempIndex = _messages.indexWhere(
            (m) => m.isOwn && m.tempId != null && _pendingTempIds.contains(m.tempId)
          );
          
          if (tempIndex != -1) {
            // Replace temp message with server-confirmed message
            final tempMsg = _messages[tempIndex];
            setState(() {
              _messages[tempIndex] = _ChatMsg(
                id: msgId,
                content: msg.content,
                senderName: msg.senderName,
                senderId: msg.senderId,
                timestamp: msg.timestamp,
                isOwn: true,
              );
              _pendingTempIds.remove(tempMsg.tempId);
            });
            debugPrint('[CHAT] Replaced temp message with server-confirmed: $msgId');
            return;
          } else {
            // We already have the optimistic message, skip server echo
            debugPrint('[CHAT] Skipped own message echo: $msgId');
            return;
          }
        }

        // Other user's message - add normally
        setState(() {
          _messages.add(msg);
          // Enforce message limit
          if (_messages.length > _maxMessages) {
            final toRemove = _messages.length - _maxMessages;
            _messages.removeRange(0, toRemove);
          }
        });
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
    final msgId = map['_id'] as String? ?? '';

    // Debug: Log sender vs current user comparison
    if (!isSystem && _myId.isNotEmpty) {
      debugPrint('[CHAT] Message from: $senderId | MyId: $_myId | IsOwn: $isOwn');
    }

    return _ChatMsg(
      id: msgId,
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

  /// Returns true if we can send (either connected or REST fallback available)
  bool get _canSend => _isConnected || !_isLoadingHistory;

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_isConnected && _socket != null) {
      _sendViaSocket(content);
    } else {
      _sendViaRest(content);
    }
  }

  void _sendViaSocket(String content) {
    // Generate temp ID for optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${_myId.isNotEmpty ? _myId.substring(0, _myId.length.clamp(0, 8)) : "u"}';
    
    // Optimistic bubble shown immediately with temp ID
    final optimistic = _ChatMsg(
      id: null, // No server ID yet
      tempId: tempId,
      content: content,
      senderName: 'You',
      senderId: _myId,
      timestamp: DateTime.now(),
      isOwn: true,
    );
    
    setState(() {
      _messages.add(optimistic);
      _pendingTempIds.add(tempId);
      // Enforce message limit
      if (_messages.length > _maxMessages) {
        final toRemove = _messages.length - _maxMessages;
        _messages.removeRange(0, toRemove);
      }
    });
    
    _messageController.clear();
    _scrollToBottom();

    debugPrint('[CHAT] Sending message via socket with tempId: $tempId');

    // Emit with server acknowledgment
    _socket!.emitWithAck(
      'chat:send',
      {'gameId': widget.game.id, 'content': content},
      ack: (data) {
        if (!mounted) return;
        // data can be null (no ack) or Map
        final ack = (data is Map) ? data as Map<String, dynamic> : null;
        
        if (ack != null && ack['success'] == false) {
          // Remove optimistic message on failure
          setState(() {
            _messages.removeWhere((m) => m.tempId == tempId);
            _pendingTempIds.remove(tempId);
          });
          debugPrint('[CHAT] Message send failed: ${ack['error']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ack['error'] as String? ?? 'Failed to send'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (ack != null && ack['success'] == true) {
          final messageId = ack['messageId'] as String?;
          if (messageId != null) {
            // Register the server-assigned ID
            _seenMsgIds.add(messageId);
            debugPrint('[CHAT] Message confirmed by server: $messageId');
          }
        }
      },
    );
  }

  Future<void> _sendViaRest(String content) async {
    if (_isSendingViaRest) return;

    // Show optimistic message
    final tempId = 'rest_temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = _ChatMsg(
      id: null,
      tempId: tempId,
      content: content,
      senderName: 'You',
      senderId: _myId,
      timestamp: DateTime.now(),
      isOwn: true,
    );

    setState(() {
      _messages.add(optimistic);
      _isSendingViaRest = true;
      if (_messages.length > _maxMessages) {
        _messages.removeRange(0, _messages.length - _maxMessages);
      }
    });
    _messageController.clear();
    _scrollToBottom();

    debugPrint('[CHAT] Sending message via REST API (socket offline)');

    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.post(
        '/games/${widget.game.id}/chat',
        data: {'content': content},
      );
      final body = resp.data as Map<String, dynamic>;
      final inner = body['data'] as Map<String, dynamic>?;
      final msgData = inner?['message'] as Map<String, dynamic>? ?? inner ?? {};

      if (!mounted) return;

      final msgId = msgData['_id'] as String? ?? '';
      setState(() {
        // Replace temp message with server-confirmed version
        final idx = _messages.indexWhere((m) => m.tempId == tempId);
        if (idx != -1 && msgId.isNotEmpty) {
          _seenMsgIds.add(msgId);
          _messages[idx] = _ChatMsg(
            id: msgId,
            content: content,
            senderName: 'You',
            senderId: _myId,
            timestamp: DateTime.now(),
            isOwn: true,
          );
        }
        _isSendingViaRest = false;
      });

      debugPrint('[CHAT] REST message sent successfully: $msgId');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.tempId == tempId);
        _isSendingViaRest = false;
      });
      debugPrint('[CHAT] REST message failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      _socket!.emit('leave:game', widget.game.id);
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
        title: Row(
          children: [
            // Game Image
            if (widget.game.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.game.imageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 40,
                    height: 40,
                    color: AppColors.surface,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 40,
                    height: 40,
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.game.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isConnected ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        _isConnected ? 'Connected' : 'Offline mode',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isConnected ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Offline banner ───────────────────────────────────────────────
          if (!_isConnected && !_isLoadingHistory)
            Material(
              color: AppColors.warning.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re offline. Messages will be sent via API.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                            : 'Type a message (offline)…',
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
                  _isSendingViaRest
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : FilledButton(
                          // Always enabled (uses REST when socket is offline)
                          onPressed: _canSend ? _sendMessage : null,
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
    this.id,
    this.tempId,
    required this.content,
    required this.senderName,
    required this.senderId,
    required this.timestamp,
    required this.isOwn,
    this.isSystem = false,
  });
  final String? id; // Server-assigned ID (null for optimistic messages)
  final String? tempId; // Temporary ID for optimistic updates
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

    // Show pending indicator for optimistic messages
    final isPending = msg.id == null;

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
                color: msg.isOwn
                    ? (isPending
                        ? cs.primary.withValues(alpha: 0.7)
                        : cs.primary)
                    : cs.surface,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  if (msg.isOwn && isPending) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.schedule_rounded,
                        size: 10,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

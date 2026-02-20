import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/api/secure_storage_provider.dart';
import '../../../../core/services/socket_service.dart';

/// Real-time chat page for a specific game room.
///
/// Navigated to via:
/// ```dart
/// Navigator.pushNamed(
///   context, AppRoutes.gameChatRoute,
///   arguments: {'gameId': game.id, 'gameTitle': game.title},
/// );
/// ```
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
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  Future<void> _initSocket() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token') ?? '';
    if (token.isEmpty) return;

    _socket = SocketService.instance.getSocket(token: token);

    _socket!
      ..on('connect', (_) {
        if (!mounted) return;
        setState(() => _isConnected = true);
        _socket!.emit('join-room', {'roomId': widget.gameId});
      })
      ..on('disconnect', (_) {
        if (!mounted) return;
        setState(() => _isConnected = false);
      })
      ..on('new-message', (data) {
        if (!mounted) return;
        final map = data as Map<String, dynamic>;
        setState(() {
          _messages.add(_ChatMsg(
            content: map['content'] as String? ?? '',
            senderName: map['senderName'] as String? ?? 'User',
            senderId: map['senderId'] as String? ?? '',
            timestamp: DateTime.tryParse(
                    map['timestamp'] as String? ?? '') ??
                DateTime.now(),
            isOwn: false,
          ));
        });
        _scrollToBottom();
      })
      ..on('user-joined', (data) {
        if (!mounted) return;
        final map = data as Map<String, dynamic>;
        setState(() {
          _messages.add(_ChatMsg(
            content: '${map['name'] ?? 'Someone'} joined the game',
            senderName: 'System',
            senderId: '',
            timestamp: DateTime.now(),
            isOwn: false,
            isSystem: true,
          ));
        });
      })
      ..on('user-left', (data) {
        if (!mounted) return;
        setState(() {
          _messages.add(_ChatMsg(
            content: 'Someone left the game',
            senderName: 'System',
            senderId: '',
            timestamp: DateTime.now(),
            isOwn: false,
            isSystem: true,
          ));
        });
      });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _socket == null) return;

    _socket!.emit('send-message', {
      'roomId': widget.gameId,
      'content': content,
    });

    setState(() {
      _messages.add(_ChatMsg(
        content: content,
        senderName: 'You',
        senderId: 'me',
        timestamp: DateTime.now(),
        isOwn: true,
      ));
    });
    _messageController.clear();
    _scrollToBottom();
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
    _socket?.emit('leave-room', {'roomId': widget.gameId});
    _socket?.off('new-message');
    _socket?.off('user-joined');
    _socket?.off('user-left');
    _socket?.off('connect');
    _socket?.off('disconnect');
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.gameTitle,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _isConnected ? 'Connected' : 'Connecting…',
              style: TextStyle(
                fontSize: 12,
                color: _isConnected ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('No messages yet',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
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
                        hintText: 'Type a message…',
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
                    onPressed: _sendMessage,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

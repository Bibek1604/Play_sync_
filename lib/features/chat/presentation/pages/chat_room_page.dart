import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_notifier.dart';
import '../../domain/entities/chat_message.dart';

/// Full chat room screen with message list and input bar.
class ChatRoomPage extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomPage({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);
    final messages = state.messagesByRoom[widget.roomId] ?? [];

    // Scroll to bottom when messages change
    ref.listen(
        chatProvider.select((s) => s.messagesByRoom[widget.roomId]?.length),
        (_, _) => _scrollToBottom());

    final room = state.rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => ChatRoom(id: widget.roomId, name: 'Chat'),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  room.avatarUrl != null ? NetworkImage(room.avatarUrl!) : null,
              child: room.avatarUrl == null
                  ? Icon(
                      room.isGroupChat ? Icons.group : Icons.person,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                if (state.isConnected)
                  Text('Connected',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade400))
                else
                  Text('Offline',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Say hello 👋'))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final showName = !msg.isFromMe &&
                          (i == 0 ||
                              messages[i - 1].senderId != msg.senderId);
                      return _MessageBubble(
                          message: msg, showSenderName: showName);
                    },
                  ),
          ),
          // Input bar
          _ChatInputBar(
            controller: _inputCtrl,
            isSending: state.isSending,
            onSend: () {
              final text = _inputCtrl.text;
              if (text.trim().isNotEmpty) {
                _inputCtrl.clear();
                ref.read(chatProvider.notifier).sendMessage(text);
                _scrollToBottom();
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showSenderName;

  const _MessageBubble({required this.message, this.showSenderName = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMe = message.isFromMe;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                message.senderName,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isMe ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? cs.onPrimary : cs.onSurface,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.sentAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: (isMe ? cs.onPrimary : cs.onSurface)
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const _ChatInputBar(
      {required this.controller,
      required this.onSend,
      required this.isSending});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {},
              color: cs.outline,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary),
                  ),
          ],
        ),
      ),
    );
  }
}

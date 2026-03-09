import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../providers/chat_notifier.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';

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
  static const double _loadMoreThreshold = 200.0;

  /// Resolved user ID — single source of truth for sender alignment.
  String _myUserId = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _resolveUserId();
  }

  /// Resolve user ID: auth providers first, secure storage fallback.
  Future<void> _resolveUserId() async {
    final auth = ref.read(authNotifierProvider);
    final vm = ref.read(authViewModelProvider);
    var id = (auth.user?.userId ?? vm.user?.userId ?? '').trim();
    if (id.isEmpty) {
      final storage = ref.read(secureStorageProvider);
      id = (await storage.read(key: 'user_id') ?? '').trim();
    }
    if (mounted && id.isNotEmpty && id != _myUserId) {
      setState(() => _myUserId = id);
    }
    debugPrint('[ChatRoom] Resolved myUserId: $id');
  }

  /// Triggers pagination when user scrolls near top.
  void _onScroll() {
    if (_scrollCtrl.position.pixels <=
        _scrollCtrl.position.minScrollExtent + _loadMoreThreshold) {
      final chatState = ref.read(chatProvider);
      if (chatState.hasMore && !chatState.isLoadingMore) {
        _triggerLoadMore();
      }
    }
  }

  void _triggerLoadMore() {
    final scrollBefore = _scrollCtrl.position.pixels;
    final maxBefore = _scrollCtrl.position.maxScrollExtent;

    ref.read(chatProvider.notifier).loadMoreMessages().then((_) {
      // Restore scroll position so older messages don't push the viewport
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          final maxAfter = _scrollCtrl.position.maxScrollExtent;
          _scrollCtrl.jumpTo(scrollBefore + (maxAfter - maxBefore));
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    ref.read(chatProvider.notifier).closeRoom();
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
    final authState = ref.watch(authNotifierProvider);
    final vmState = ref.watch(authViewModelProvider);
    final freshId = (authState.user?.userId ?? vmState.user?.userId ?? '').trim();
    // Update _myUserId if auth providers now have the ID but secure storage didn't
    if (freshId.isNotEmpty && _myUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _myUserId = freshId);
      });
    }
    final currentUserId = _myUserId.isNotEmpty ? _myUserId : freshId;

    // Scroll to bottom when messages change
    ref.listen(
        chatProvider.select((s) => s.messagesByRoom[widget.roomId]?.length),
        (_, _) => _scrollToBottom());

    final room = state.rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => ChatRoom(id: widget.roomId, name: 'Chat'),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const AppDrawer(),
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
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.more_vert), onPressed: () {}),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messages.isEmpty && state.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('Say hello 👋'))
                    : ListView.builder(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    // +1 item at top for pagination indicator
                    itemCount: messages.length + (state.isLoadingMore || state.hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      // First item: load-more indicator
                      if ((state.isLoadingMore || state.hasMore) && i == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : TextButton.icon(
                                    onPressed: _triggerLoadMore,
                                    icon: const Icon(Icons.expand_less_rounded, size: 18),
                                    label: const Text('Load older messages'),
                                    style: TextButton.styleFrom(
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                          ),
                        );
                      }
                      final msgIdx = i - (state.isLoadingMore || state.hasMore ? 1 : 0);
                      final msg = messages[msgIdx];
                      final showName = !msg.isFromMe(currentUserId) &&
                          (msgIdx == 0 ||
                              messages[msgIdx - 1].senderId != msg.senderId);
                      return _MessageBubble(
                          message: msg, currentUserId: currentUserId, showSenderName: showName);
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
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String currentUserId;
  final bool showSenderName;

  const _MessageBubble({required this.message, required this.currentUserId, this.showSenderName = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMe = message.isSystemMessage ? false : message.isFromMe(currentUserId);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
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
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
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

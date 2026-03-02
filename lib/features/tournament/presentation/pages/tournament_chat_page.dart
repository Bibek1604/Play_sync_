import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/tournament_chat_message.dart';
import '../providers/tournament_chat_notifier.dart';

/// Real-time chat page for a tournament room (payment-gated).
class TournamentChatPage extends ConsumerStatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentChatPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  ConsumerState<TournamentChatPage> createState() =>
      _TournamentChatPageState();
}

class _TournamentChatPageState extends ConsumerState<TournamentChatPage> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _showParticipants = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tournamentChatProvider.notifier).joinRoom(widget.tournamentId);
    });
  }

  @override
  void dispose() {
    ref.read(tournamentChatProvider.notifier).leaveRoom();
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _myId => ref.read(authNotifierProvider).user?.userId ?? '';

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
  Widget build(BuildContext context) {
    final chatState = ref.watch(tournamentChatProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Auto-scroll on new messages
    if (chatState.messages.isNotEmpty) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tournamentName, style: const TextStyle(fontSize: 16)),
            Text(
              chatState.isConnected
                  ? '${chatState.participants.length} participants'
                  : 'Connecting...',
              style: TextStyle(
                fontSize: 12,
                color: chatState.isConnected ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showParticipants ? Icons.chat : Icons.people),
            tooltip:
                _showParticipants ? 'Show Chat' : 'Show Participants',
            onPressed: () =>
                setState(() => _showParticipants = !_showParticipants),
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (chatState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.error.withAlpha(25),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(chatState.error!,
                        style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: _showParticipants
                ? _buildParticipantsList(chatState, theme)
                : _buildMessagesList(chatState, theme, isDark),
          ),

          // Input
          if (!_showParticipants) _buildMessageInput(chatState, isDark),
        ],
      ),
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  Widget _buildMessagesList(
      TournamentChatState state, ThemeData theme, bool isDark) {
    if (state.isLoadingHistory && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No messages yet. Say hello!',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final msg = state.messages[index];
        final isMe = _isMyMessage(msg);
        return _MessageBubble(message: msg, isMe: isMe, isDark: isDark);
      },
    );
  }

  bool _isMyMessage(TournamentChatMessage msg) {
    if (msg.userId is TournamentChatUser) {
      return (msg.userId as TournamentChatUser).id == _myId;
    }
    return msg.userId?.toString() == _myId;
  }

  // ── Input ─────────────────────────────────────────────────────────────────

  Widget _buildMessageInput(TournamentChatState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                decoration: InputDecoration(
                  hintText:
                      state.isConnected ? 'Type a message...' : 'Connecting...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                enabled: state.isConnected,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: state.isConnected ? _send : null,
              icon: const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final content = _messageCtrl.text.trim();
    if (content.isEmpty) return;
    ref.read(tournamentChatProvider.notifier).sendMessage(content);
    _messageCtrl.clear();
  }

  // ── Participants Panel ────────────────────────────────────────────────────

  Widget _buildParticipantsList(TournamentChatState state, ThemeData theme) {
    if (state.participants.isEmpty) {
      return const Center(child: Text('No participants loaded'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.participants.length,
      itemBuilder: (context, index) {
        final p = state.participants[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                p.avatar != null ? NetworkImage(p.avatar!) : null,
            child: p.avatar == null
                ? Text(p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?')
                : null,
          ),
          title: Text(p.fullName),
          trailing: p.isCreator
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Creator',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                )
              : null,
        );
      },
    );
  }
}

// ── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final TournamentChatMessage message;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = message.userId is TournamentChatUser
        ? (message.userId as TournamentChatUser).fullName ?? 'User'
        : 'User';
    final time = _formatTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : null,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withAlpha(180)
                          : Colors.grey.shade500,
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

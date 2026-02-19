import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:play_sync_new/features/game/domain/entities/chat_message.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';

/// Professional Chat Panel Widget
///
/// Green & white theme. Sender on right (green), receiver on left (white).
/// Rounded bubbles (18px), timestamps, clean input field.
class ChatPanel extends StatefulWidget {
  final List<ChatMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final bool isSending;
  final bool isDisabled;
  final String currentUserId;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSendMessage,
    this.isSending = false,
    this.isDisabled = false,
    this.currentUserId = '',
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Messages list
        Expanded(
          child: widget.messages.isEmpty
              ? _EmptyMessages(isDark: isDark)
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    final isOwn = msg.senderId == widget.currentUserId &&
                        widget.currentUserId.isNotEmpty;
                    return _MessageBubble(
                      message: msg,
                      isOwn: isOwn,
                      isDark: isDark,
                    );
                  },
                ),
        ),

        // Input area
        _ChatInput(
          controller: widget.controller,
          onSend: widget.onSendMessage,
          isSending: widget.isSending,
          isDisabled: widget.isDisabled,
          isDark: isDark,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _SystemBubble(message: message, isDark: isDark);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left avatar (receiver)
          if (!isOwn) ...[
            _Avatar(name: message.senderName, imageUrl: message.senderAvatar),
            const SizedBox(width: 6),
          ],

          // Bubble + time
          Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender name (only for received messages)
              if (!isOwn)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald600,
                    ),
                  ),
                ),

              // Bubble
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOwn
                      ? AppColors.emerald500
                      : (isDark
                          ? AppColors.backgroundSecondaryDark
                          : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        Radius.circular(isOwn ? 18 : 4),
                    bottomRight:
                        Radius.circular(isOwn ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOwn
                          ? AppColors.emerald500.withOpacity(0.25)
                          : Colors.black.withOpacity(
                              isDark ? 0.2 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: isOwn
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                    height: 1.4,
                  ),
                ),
              ),

              // Timestamp
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ],
          ),

          // Right avatar space (own messages) — no avatar shown
          if (isOwn) const SizedBox(width: 2),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// System message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _SystemBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.emerald400, AppColors.teal400],
        ),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _NameInitial(name: name)),
            )
          : _NameInitial(name: name),
    );
  }
}

class _NameInitial extends StatelessWidget {
  final String name;

  const _NameInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat input
// ─────────────────────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final bool isDisabled;
  final bool isDark;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.isDisabled,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundSecondaryDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF2FAF6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.grey.withOpacity(0.2)
                        : AppColors.emerald500.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isDisabled && !isSending,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: isDisabled ? null : (_) => onSend(),
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: isDisabled
                        ? 'Chat unavailable'
                        : 'Type a message...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: (isDisabled || isSending) ? null : onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: (isDisabled || isSending)
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.emerald500, AppColors.teal500],
                        ),
                  color: (isDisabled || isSending)
                      ? Colors.grey.withOpacity(0.3)
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: (isDisabled || isSending)
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.emerald500.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty messages state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMessages extends StatelessWidget {
  final bool isDark;

  const _EmptyMessages({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to say hello!',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}


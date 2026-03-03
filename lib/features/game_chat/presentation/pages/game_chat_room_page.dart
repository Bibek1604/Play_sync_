import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/view_model/auth_viewmodel.dart';
import '../../domain/entities/message_entity.dart';
import '../notifiers/game_chat_notifier.dart';
import '../../../game/domain/entities/game_entity.dart';
import '../../../../core/services/socket_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../data/models/message_model.dart';

/// Clean-architecture game chat room screen.
///
/// Opens for a [gameId] and [gameTitle].  On init it loads chat history
/// once via GET.  Sending uses POST and appends only the returned message.
///
/// Alignment rule (single bubble, never duplicated):
///   message.isMe(currentUserId) == true  → RIGHT, primary-blue bubble
///   message.isMe(currentUserId) == false → LEFT,  grey bubble
class GameChatRoomPage extends ConsumerStatefulWidget {
  final String gameId;
  final String gameTitle;
  final String? gameImageUrl;

  const GameChatRoomPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
    this.gameImageUrl,
  });

  @override
  ConsumerState<GameChatRoomPage> createState() => _GameChatRoomPageState();
}

class _GameChatRoomPageState extends ConsumerState<GameChatRoomPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  /// Resolved current-user ID — single source of truth for alignment.
  String _currentUserId = '';
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    // 1. Resolve user ID instantly from in-memory if available
    _resolveUserIdImmediate();
    
    // 2. Background resolve from storage (fallback / confirm)
    _resolveUserId().then((_) {
      // 3. Once we have ID, attempt to join socket room if available
      _setupSocket();
    });

    // 4. Load history on open — called exactly once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameChatNotifierProvider(widget.gameId).notifier).loadMessages();
    });
  }

  /// Synchronously grabs identity from providers if already logged in.
  /// This prevents the "render on left" flicker on physical devices.
  void _resolveUserIdImmediate() {
    final authState = ref.read(authNotifierProvider);
    final vmState = ref.read(authViewModelProvider);
    final rawId = authState.user?.userId ?? vmState.user?.userId;
    final id = GameEntity.normalize(rawId);
    
    if (id.isNotEmpty) {
      _currentUserId = id;
    }
  }

  Future<void> _setupSocket() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');
    if (token == null || token.isEmpty) return;

    _socket = SocketService.instance.getSocket(token: token);

    if (_socket!.connected) {
      _joinRoom();
    }

    _socket!.onConnect((_) => _joinRoom());

    _socket!.on('chat:message', (data) {
      if (!mounted) return;
      try {
        final incoming = MessageModel.fromJson(
          data as Map<String, dynamic>,
          widget.gameId,
        );
        ref
            .read(gameChatNotifierProvider(widget.gameId).notifier)
            .appendIncoming(incoming, _currentUserId);
      } catch (e) {
        debugPrint('[ChatSocket] Error parsing incoming: $e');
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[ChatSocket] Disconnected: $reason');
    });
  }

  void _joinRoom() {
    if (_socket != null && _socket!.connected) {
      debugPrint('[ChatSocket] Joining room: ${widget.gameId}');
      _socket!.emit('join:game', widget.gameId);
    }
  }

  void _leaveRoom() {
    if (_socket != null) {
      debugPrint('[ChatSocket] Leaving room: ${widget.gameId}');
      _socket!.emit('leave:game', widget.gameId);
      _socket!.off('chat:message');
    }
  }

  /// Reads user ID from providers (instant) then falls back to secure storage.
  Future<void> _resolveUserId() async {
    final auth = ref.read(authNotifierProvider);
    final vm = ref.read(authViewModelProvider);
    final rawId = auth.user?.userId ?? vm.user?.userId;
    var id = GameEntity.normalize(rawId);

    if (id.isEmpty) {
      final storage = ref.read(secureStorageProvider);
      final storedId = await storage.read(key: 'user_id');
      id = GameEntity.normalize(storedId);
    }

    if (mounted && id.isNotEmpty && id != _currentUserId) {
      setState(() => _currentUserId = id);
    }
  }

  @override
  void dispose() {
    _leaveRoom();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    // 1. Clear input immediately so the user can type again
    _inputCtrl.clear();
    _focusNode.requestFocus();

    // 2. Call notifier — waits for POST response, appends confirmed message
    final ok = await ref
        .read(gameChatNotifierProvider(widget.gameId).notifier)
        .sendMessage(text);

    // 3. Scroll to bottom after the new bubble is rendered
    if (ok) _scrollToBottom();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(gameChatNotifierProvider(widget.gameId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── IDENTITY RESOLUTION (SYNCHRONOUS) ──────────────────────────────
    // Watch the reactive user info (ID + Name) for robust alignment checks.
    final userInfo = ref.watch(currentUserInfoProvider);
    final bestId = userInfo.id.isNotEmpty ? userInfo.id : _currentUserId;

    if (bestId.isNotEmpty && _currentUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentUserId = bestId);
      });
    }

    // Auto-scroll when message count grows
    ref.listen(
      gameChatNotifierProvider(widget.gameId).select((s) => s.messages.length),
      (prev, next) => _scrollToBottom(),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // ── Error banner ─────────────────────────────────────────────────
          if (chatState.error != null)
            _ErrorBanner(
              message: chatState.error!,
              onDismiss: () => ref
                  .read(gameChatNotifierProvider(widget.gameId).notifier)
                  .clearError(),
            ),

          // ── Message list ─────────────────────────────────────────────────
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                    ? _EmptyState(isDark: isDark)
                    : _MessageList(
                        messages: chatState.messages,
                        currentUserId: bestId,
                        currentUserName: userInfo.name,
                        scrollCtrl: _scrollCtrl,
                        isDark: isDark,
                      ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          _InputBar(
            controller: _inputCtrl,
            focusNode: _focusNode,
            isSending: chatState.isSending,
            onSend: _sendMessage,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.cardDark : AppColors.surface,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Row(
        children: [
          // Avatar
          _Avatar(imageUrl: widget.gameImageUrl, title: widget.gameTitle),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.gameTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Game Chat',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<MessageEntity> messages;
  final String currentUserId;
  final String currentUserName;
  final ScrollController scrollCtrl;
  final bool isDark;

  _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.currentUserName,
    required this.scrollCtrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];

        // Show sender name only when it's a new sender group (others only)
        final showName =
            !msg.isMe(currentUserId, currentUserName: currentUserName) &&
                (i == 0 || messages[i - 1].senderId != msg.senderId);

        return _MessageBubble(
          message: msg,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          showSenderName: showName,
          isDark: isDark,
        );
      },
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final String currentUserId;
  final String currentUserName;
  final bool showSenderName;
  final bool isDark;

  _MessageBubble({
    required this.message,
    required this.currentUserId,
    required this.currentUserName,
    this.showSenderName = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    // ── THE CORE RULE ─────────────────────────────────────────────────────
    // isMe == true  → RIGHT side, blue bubble
    // isMe == false → LEFT side, grey bubble
    // ONE bubble. No duplication. No cross-rendering.
    final isMe = message.isMe(currentUserId, currentUserName: currentUserName);

    // System messages: centred pill
    if (message.isSystemMessage) {
      return _SystemBubble(text: message.text, isDark: isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar (left side / others only)
          if (!isMe) ...[
            _SenderAvatar(
              name: message.senderName,
              avatarUrl: message.senderAvatar,
            ),
            const SizedBox(width: 8),
          ],

          // The single bubble
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name (for group context, others only)
                if (showSenderName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                // Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.chatBubbleOwn
                        : (isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: isMe
                          ? Colors.white
                          : (isDark
                              ? Colors.white
                              : AppColors.textPrimary),
                    ),
                  ),
                ),

                // Timestamp
                Padding(
                  padding:
                      const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.white38
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Spacer on right for others' bubbles (keeps them away from edge)
          if (!isMe) const SizedBox(width: 42),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── System Bubble ────────────────────────────────────────────────────────────

class _SystemBubble extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SystemBubble({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sender Avatar ────────────────────────────────────────────────────────────

class _SenderAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _SenderAvatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primaryLight,
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            )
          : null,
    );
  }
}

// ─── App Bar Avatar ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String title;
  const _Avatar({this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? const Icon(Icons.sports_esports_rounded,
              size: 18, color: AppColors.primary)
          : null,
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final bool isDark;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white12
                  : AppColors.borderSubtle,
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  // Allow Enter on web/desktop to submit
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white10
                        : AppColors.surfaceLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button / spinner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSending
                  ? const SizedBox(
                      key: ValueKey('spinner'),
                      width: 44,
                      height: 44,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary),
                      ),
                    )
                  : Material(
                      key: const ValueKey('button'),
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: onSend,
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 60,
            color: isDark
                ? Colors.white24
                : AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Say hello to your team! 👋',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white38
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.errorLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: AppColors.error, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.error),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/game_entity.dart';
import '../../../../core/widgets/back_button_widget.dart';

/// Simple REST-based chat page for a game.
/// 
/// No Socket.IO complexity. Pure REST API implementation:
/// - GET  /api/v1/games/:gameId/chat  → Fetch messages
/// - POST /api/v1/games/:gameId/chat  → Send message
/// 
/// Messages are fetched on open and when sending.
class GameChatRestPage extends ConsumerStatefulWidget {
  const GameChatRestPage({super.key, required this.game});

  final GameEntity game;

  @override
  ConsumerState<GameChatRestPage> createState() => _GameChatRestPageState();
}

class _GameChatRestPageState extends ConsumerState<GameChatRestPage> {
  final _scrollController = ScrollController();
  final _messageController = TextEditingController();

  List<_Message> _messages = [];
  bool _isLoadingHistory = true;
  bool _isSending = false;
  String _myUserId = '';

  @override
  void initState() {
    super.initState();
    _resolveUserId();
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Resolve current user ID from auth state or secure storage
  Future<void> _resolveUserId() async {
    try {
      // 1. Try auth providers first
      final auth = ref.read(authNotifierProvider);
      var id = (auth.user?.userId ?? '').trim();

      // 2. Fallback to secure storage
      if (id.isEmpty) {
        final storage = ref.read(secureStorageProvider);
        id = (await storage.read(key: 'user_id') ?? '').trim();
      }

      if (mounted && id.isNotEmpty) {
        setState(() => _myUserId = id);
        debugPrint('[CHAT REST] ✓ Resolved user ID: $id');
      }
    } catch (e) {
      debugPrint('[CHAT REST] ❌ Failed to resolve user ID: $e');
    }
  }

  /// Load chat messages from server
  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() => _isLoadingHistory = true);

    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get(
        ApiEndpoints.getChatMessages(widget.game.id),
        queryParameters: {'limit': 50},
      );

      final body = resp.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final messagesList = (data['messages'] as List?) ?? [];

      if (!mounted) return;

      setState(() {
        _messages = messagesList
            .map((m) => _Message.fromJson(m as Map<String, dynamic>))
            .toList();
        _isLoadingHistory = false;
      });

      _scrollToBottom();
      debugPrint('[CHAT REST] ✓ Loaded ${_messages.length} messages');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingHistory = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load chat. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      debugPrint('[CHAT REST] ❌ Failed to load messages: $e');
    }
  }

  /// Send message via REST API
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.post(
        ApiEndpoints.sendChatMessage(widget.game.id),
        data: {'content': text},
      );

      final body = resp.data as Map<String, dynamic>;
      final messageData = body['data'] as Map<String, dynamic>?;

      if (messageData == null) {
        throw Exception('Invalid response');
      }

      if (!mounted) return;

      // Add the returned message to the list (only server response)
      final message = _Message.fromJson(messageData);

      setState(() {
        _messages.add(message);
        _isSending = false;
      });

      _scrollToBottom();
      debugPrint('[CHAT REST] ✓ Message sent');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSending = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      debugPrint('[CHAT REST] ❌ Failed to send message: $e');
    }
  }

  /// Scroll to bottom of messages
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(widget.game.title),
        centerTitle: false,
        leading: const BackButtonWidget(),
      ),
      body: Column(
        children: [
          // ── Messages List ──────────────────────────────────────────────
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // Robust comparison: normalize both IDs
                          final isMe = _myUserId.isNotEmpty && 
                              message.senderId.trim() == _myUserId.trim();

                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      ),
          ),

          // ── Message Input ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _isSending ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(12),
                      child: _isSending
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                    ),
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

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  final _Message message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage: message.senderAvatar != null &&
                      message.senderAvatar!.isNotEmpty
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null ||
                      message.senderAvatar!.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Local message model
class _Message {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;

  const _Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
  });

  factory _Message.fromJson(Map<String, dynamic> json) {
    // Try new format first (senderId field)
    final newFormatSenderId = json['senderId'] as String?;
    
    if (newFormatSenderId != null && newFormatSenderId.isNotEmpty) {
      // New REST API format
      final senderName = (json['senderName'] as String?)?.trim() ?? 'Unknown';
      return _Message(
        id: json['_id'] as String? ?? '',
        senderId: (newFormatSenderId).trim(),
        senderName: senderName.isNotEmpty ? senderName : 'Unknown',
        senderAvatar: (json['senderAvatar'] as String?)?.trim(),
        text: json['text'] as String? ?? '',
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
    }
    
    // Fallback: Old backend format with nested user object
    final userObj = (json['user'] as Map<String, dynamic>?);
    
    // If user is null (system message), use default
    if (userObj == null) {
      return _Message(
        id: json['_id'] as String? ?? '',
        senderId: '',
        senderName: 'System',
        senderAvatar: null,
        text: json['content'] as String? ?? '',
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
    }
    
    // Extract sender name with proper trimming
    final fullName = (userObj['fullName'] as String?)?.trim() ?? '';
    final username = (userObj['username'] as String?)?.trim() ?? '';
    final senderName = fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : 'Unknown');
    final senderId = (userObj['_id'] as String?) ?? (userObj['id'] as String?) ?? '';
    
    return _Message(
      id: json['_id'] as String? ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: userObj['profilePicture'] as String?,
      text: json['content'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

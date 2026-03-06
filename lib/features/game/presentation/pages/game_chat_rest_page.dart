import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/secure_storage_provider.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/game_entity.dart';
import '../../../../core/widgets/back_button_widget.dart';
import '../providers/game_notifier.dart';

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
            .where((msg) {
              // Filter out system messages by type field
              final isSystemMessage = msg.type == 'system';
              // Filter out messages with no actual text content
              final hasContent = msg.text.trim().isNotEmpty;
              return hasContent && !isSystemMessage;
            })
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sort oldest first
        _isLoadingHistory = false;
      });

      _scrollToBottom();
      debugPrint('[CHAT REST] ✓ Loaded ${_messages.length} chat messages (system messages filtered)');
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
      
      // Try multiple paths for message data
      var messageData = body['data'] as Map<String, dynamic>? ?? 
                        body['message'] as Map<String, dynamic>?;

      if (messageData == null) {
        throw Exception('Invalid response - no message data returned');
      }

      if (!mounted) return;

      // Ensure senderId is populated with current user's ID if missing
      if ((messageData['senderId'] == null || messageData['senderId'].toString().isEmpty) &&
          _myUserId.isNotEmpty) {
        messageData['senderId'] = _myUserId;
        debugPrint('[CHAT REST] Added senderId: $_myUserId');
      }
      
      // Ensure we have the user's info even if server doesn't return it
      if (messageData['senderName'] == null || messageData['senderName'].toString().isEmpty) {
        final auth = ref.read(authNotifierProvider);
        final userName = auth.user?.fullName ?? auth.user?.email ?? 'You';
        messageData['senderName'] = userName;
        debugPrint('[CHAT REST] Added senderName: $userName');
      }
      
      // Ensure type is set to 'text' for normal messages
      if (messageData['type'] == null) {
        messageData['type'] = 'text';
      }
      
      final message = _Message.fromJson(messageData);
      
      debugPrint('[CHAT REST] Created message - ID: ${message.id}, SenderID: ${message.senderId}, SenderName: ${message.senderName}');

      setState(() {
        // Check if message already exists to prevent duplicates
        final exists = _messages.any((m) => m.id == message.id && message.id.isNotEmpty);
        if (!exists) {
          _messages.add(message);
          // Keep messages sorted by time (oldest first)
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        _isSending = false;
      });

      _scrollToBottom();
      debugPrint('[CHAT REST] ✓ Message sent and displayed');
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

  /// Handle leaving the game
  Future<void> _handleLeaveGame(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text(
          'Are you sure you want to leave this game? You won\'t be able to access it or send messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm || !mounted) return;

    try {
      // Leave the game via game provider
      final result = await ref.read(gameProvider.notifier).leaveGame(widget.game.id);
      
      if (!mounted) return;

      if (result != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You left the game. It has been removed from your chats.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Pop back to navigate away from this chat
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to leave game. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error leaving game: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _handleLeaveGame(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Leave Game', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ],
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
                          
                          // Skip messages with no valid sender name UNLESS it's from current user
                          if (message.senderName.isEmpty && !isMe) {
                            return const SizedBox.shrink();
                          }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.2),
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
                        fontSize: 13,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : (isDark ? AppColors.surfaceDark : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 0.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!isMe) const SizedBox(height: 6),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF1F1F1F)),
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withOpacity(0.6)
                          : (isDark ? AppColors.textTertiary : AppColors.textSecondary),
                      fontWeight: FontWeight.w400,
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
  final String type; // 'text' or 'system'
  final DateTime createdAt;

  const _Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    this.type = 'text',
    required this.createdAt,
  });

  factory _Message.fromJson(Map<String, dynamic> json) {
    // Try new format first (senderId field) - PRIORITIZE THIS
    final newFormatSenderId = json['senderId'] as String?;
    final newFormatSenderName = (json['senderName'] as String?)?.trim();
    final messageType = (json['type'] as String?) ?? 'text';
    
    if (newFormatSenderId != null && newFormatSenderId.isNotEmpty) {
      // New REST API format with direct fields
      // Keep empty sender name if not provided (for current user's messages)
      final senderName = newFormatSenderName ?? '';
      return _Message(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        senderId: newFormatSenderId.trim(),
        senderName: senderName,
        senderAvatar: (json['senderAvatar'] as String?)?.trim(),
        text: json['text'] as String? ?? json['content'] as String? ?? '',
        type: messageType,
        createdAt: _parseDateTime(json['createdAt']),
      );
    }
    
    // Fallback: Old backend format with nested user object
    final userObj = (json['user'] as Map<String, dynamic>?);
    
    if (userObj != null) {
      // Extract sender name with proper trimming
      final fullName = (userObj['fullName'] as String?)?.trim() ?? '';
      final username = (userObj['username'] as String?)?.trim() ?? '';
      final displayName = userObj['displayName'] as String?;
      final senderName = displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : ''));
      final senderId = (userObj['_id'] as String?) ?? (userObj['id'] as String?) ?? '';
      
      return _Message(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        senderId: senderId,
        senderName: senderName,
        senderAvatar: userObj['profilePicture'] as String? ?? userObj['avatar'] as String?,
        text: json['content'] as String? ?? json['text'] as String? ?? '',
        type: messageType,
        createdAt: _parseDateTime(json['createdAt']),
      );
    }
    
    // Fallback: If sender info is completely missing, but we have content
    // Return empty sender name to filter this message out in UI
    return _Message(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      senderId: '',
      senderName: '',
      senderAvatar: null,
      text: json['content'] as String? ?? json['text'] as String? ?? '',
      type: messageType,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
  
  /// Parse datetime safely
  static DateTime _parseDateTime(dynamic dateValue) {
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
}

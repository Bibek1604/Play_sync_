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
import 'package:play_sync_new/features/game/presentation/providers/game_notifier.dart';
import '../../domain/entities/game_entity.dart';
import 'game_detail_page.dart';
import '../../../chat/presentation/providers/chat_notifier.dart';
import '../../../../core/widgets/back_button_widget.dart';

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
  bool _isLoadingHistory = true;
  bool _isSending = false;
  static const int _maxMessages = 200; // Increased to support pagination
  int _currentPlayerCount = 0;

  // ── Pagination state ────────────────────────────────────────────────────
  bool _hasMore = false;
  String? _nextCursor;
  bool _isLoadingMore = false;
  static const int _pageSize = 50;
  static const double _loadMoreThreshold = 200.0;

  /// Resolved user ID — single source of truth for sender alignment.
  /// Read from secure storage in initState (guaranteed after login),
  /// updated from auth providers as a fallback.
  String _myUserId = '';

  @override
  void initState() {
    super.initState();
    _currentPlayerCount = widget.game.currentPlayers;
    _scrollController.addListener(_onScroll);
    _resolveUserId();
    _loadHistory();
    _initSocket();
  }

  /// Resolve the current user's ID from multiple sources.
  /// Priority: auth providers (sync) → secure storage (async fallback).
  Future<void> _resolveUserId() async {
    // 1. Try auth providers first (may already be loaded)
    final auth = ref.read(authNotifierProvider);
    final vm = ref.read(authViewModelProvider);
    var id = (auth.user?.userId ?? vm.user?.userId ?? '').trim();

    // 2. Fallback: read from secure storage (always has it after login)
    if (id.isEmpty) {
      final storage = ref.read(secureStorageProvider);
      id = (await storage.read(key: 'user_id') ?? '').trim();
    }
    
    id = GameEntity.normalize(id);

    if (mounted && id.isNotEmpty && id != _myUserId) {
      setState(() => _myUserId = id);
    }
    debugPrint('[CHAT] Resolved myUserId (normalized): $id');
  }

  /// Triggers loading older messages when user scrolls near top.
  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + _loadMoreThreshold &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  // ── History ──────────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get(
        '/games/${widget.game.id}/chat',
        queryParameters: {'limit': _pageSize},
      );
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
        _hasMore = inner?['hasMore'] as bool? ?? false;
        _nextCursor = inner?['nextCursor'] as String?;
        _isLoadingHistory = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  /// Loads older messages when user scrolls to top.
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    // Preserve scroll position so new items don't push the viewport down
    final scrollBefore = _scrollController.position.pixels;
    final maxBefore = _scrollController.position.maxScrollExtent;

    try {
      final api = ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{'limit': _pageSize};
      if (_nextCursor != null) {
        queryParams['before'] = _nextCursor;
      }
      final resp = await api.get(
        '/games/${widget.game.id}/chat',
        queryParameters: queryParams,
      );
      final body = resp.data as Map<String, dynamic>;
      final inner = body['data'] as Map<String, dynamic>?;
      final rawList = (inner?['messages'] as List?) ?? [];
      if (!mounted) return;

      final older = <_ChatMsg>[];
      for (final raw in rawList.reversed) {
        final map = raw as Map<String, dynamic>;
        final id = map['_id'] as String? ?? '';
        if (id.isNotEmpty && !_seenMsgIds.add(id)) continue; // skip dups
        older.add(_parseDTO(map));
      }

      setState(() {
        _messages.insertAll(0, older);
        // Enforce limit (trim from top, keeping newest)
        if (_messages.length > _maxMessages) {
          _messages.removeRange(0, _messages.length - _maxMessages);
        }
        _hasMore = inner?['hasMore'] as bool? ?? false;
        _nextCursor = inner?['nextCursor'] as String?;
        _isLoadingMore = false;
      });

      // Restore relative scroll position so the user stays at the same message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final maxAfter = _scrollController.position.maxScrollExtent;
          _scrollController
              .jumpTo(scrollBefore + (maxAfter - maxBefore));
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
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
      _socket!.emit('join:game', widget.game.id);
    }

    _socket!
      ..on('connect', (_) {
        if (!mounted) return;
        _socket!.emit('join:game', widget.game.id);
      })
      ..on('disconnect', (_) {
        if (!mounted) return;
      })
      ..on('game:player:joined', (data) {
        if (!mounted) return;
        final raw = data as Map<String, dynamic>;
        final count = raw['currentPlayers'] as int?;
        if (count != null) setState(() => _currentPlayerCount = count);
      })
      ..on('game:player:left', (data) {
        if (!mounted) return;
        final raw = data as Map<String, dynamic>;
        final count = raw['currentPlayers'] as int?;
        if (count != null) setState(() => _currentPlayerCount = count);
      })
      ..on('chat:message', (data) {
        if (!mounted) return;
        final raw = data as Map<String, dynamic>;
        final msgId = GameEntity.normalize(raw['_id'] ?? raw['id']);
        final msg = _parseDTO(raw);
        final myIdNorm = GameEntity.normalize(_myUserId);
        final senderIdNorm = GameEntity.normalize(msg.senderId);
        final bool isMe = !msg.isSystem && myIdNorm.isNotEmpty && senderIdNorm == myIdNorm;

        debugPrint('[CHAT] Socket Msg: ID=$msgId | From=$senderIdNorm | isMe=$isMe');

        if (isMe) {
          final tempIdx = _messages.indexWhere((m) =>
              m.tempId != null && _pendingTempIds.contains(m.tempId));

          if (tempIdx != -1) {
            final tempMsg = _messages[tempIdx];
            setState(() {
              _messages[tempIdx] = _ChatMsg(
                id: msgId,
                content: msg.content,
                senderName: 'You',
                senderId: _myUserId,
                timestamp: msg.timestamp,
                avatarUrl: msg.avatarUrl,
              );
              _pendingTempIds.remove(tempMsg.tempId);
              if (msgId.isNotEmpty) _seenMsgIds.add(msgId);
            });
            debugPrint('[CHAT] Replaced temp ${tempMsg.tempId} with $msgId');
            _scrollToBottom();
            return;
          }
        }

        if (msgId.isNotEmpty && !_seenMsgIds.add(msgId)) {
          debugPrint('[CHAT] Skipped duplicate message ID: $msgId');
          return;
        }

        // Final safety check: if we already have a message with this server ID, don't add it
        final alreadyPresent = _messages.any((m) => m.id == msgId && msgId.isNotEmpty);
        if (alreadyPresent) return;

        setState(() {
          _messages.add(msg);
          if (_messages.length > _maxMessages) {
            _messages.removeRange(0, _messages.length - _maxMessages);
          }
        });
        _scrollToBottom();
      });
  }

  // ── Message parsing ───────────────────────────────────────────────────────

  /// Parses a backend ChatMessageDTO into a local [_ChatMsg].
  ///
  /// Supports both API formats:
  ///
  /// New format (current backend):
  /// ```json
  /// {
  ///   "_id": "...",
  ///   "senderId": "userId",
  ///   "senderName": "Full Name",
  ///   "senderAvatar": "url | null",
  ///   "text": "message content",
  ///   "type": "text" | "system",
  ///   "createdAt": "<ISO string>"
  /// }
  /// ```
  ///
  /// Old format (legacy fallback):
  /// ```json
  /// {
  ///   "_id": "...",
  ///   "user": { "_id": "...", "username": "...", "fullName": "...", "profilePicture": "..." } | null,
  ///   "content": "...",
  ///   "type": "text" | "system",
  ///   "createdAt": "<ISO string>"
  /// }
  /// ```
  _ChatMsg _parseDTO(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'text';
    final isSystem = type == 'system';
    final msgId = GameEntity.normalize(map['_id'] ?? map['id']);

    // ── NEW format: flat senderId / senderName / text ──────────────────────
    final newSenderId = map['senderId'] as String?;
    if (newSenderId != null && newSenderId.isNotEmpty) {
      final senderId = GameEntity.normalize(newSenderId);
      final senderName = (map['senderName'] as String?)?.trim();
      final avatarUrl = map['senderAvatar'] as String?;
      // New format uses 'text', old uses 'content'
      final content = (map['text'] as String?)?.isNotEmpty == true
          ? map['text'] as String
          : (map['content'] as String? ?? '');

      return _ChatMsg(
        id: msgId,
        content: content,
        senderName: isSystem ? 'System' : (senderName?.isNotEmpty == true ? senderName! : 'User'),
        senderId: isSystem ? '' : senderId,
        timestamp: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        isSystem: isSystem,
        avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl : null,
      );
    }

    // ── OLD format: nested user object / content ───────────────────────────
    final rawUser = map['user'];
    String senderId = '';
    String senderName = 'User';
    String? avatarUrl;

    if (rawUser is Map<String, dynamic>) {
      senderId = GameEntity.normalize(rawUser['_id'] ?? rawUser['id']);
      senderName = (rawUser['fullName'] as String? ??
          rawUser['username'] as String? ??
          'User');
      avatarUrl = rawUser['profilePicture'] as String?
          ?? rawUser['profileImage'] as String?
          ?? rawUser['avatar'] as String?;
    } else if (rawUser != null) {
      senderId = GameEntity.normalize(rawUser);
    }

    return _ChatMsg(
      id: msgId,
      content: map['content'] as String? ?? '',
      senderName: isSystem ? 'System' : senderName,
      senderId: isSystem ? '' : senderId,
      timestamp: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      isSystem: isSystem,
      avatarUrl: avatarUrl?.isNotEmpty == true ? avatarUrl : null,
    );
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  /// Returns true if we can send (either connected or REST fallback available)
  bool get _canSend => (_socket?.connected ?? false) || !_isLoadingHistory;

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    // 1. Setup optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = _ChatMsg(
      id: null,
      tempId: tempId,
      content: content,
      senderName: 'You',
      senderId: _myUserId,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(optimistic);
      _pendingTempIds.add(tempId);
      _isSending = true;
      if (_messages.length > _maxMessages) {
        _messages.removeRange(0, _messages.length - _maxMessages);
      }
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      if (_socket != null && _socket!.connected) {
        // Path A: Socket
        _socket!.emitWithAck(
          'chat:send',
          {'gameId': widget.game.id, 'content': content},
          ack: (data) {
            if (!mounted) return;
            final ack = (data is Map) ? data as Map<String, dynamic> : null;
            if (ack != null && ack['success'] == false) {
              _handleSendFailure(tempId, ack['error'] as String?);
            } else if (ack != null && ack['success'] == true) {
              final messageId = ack['messageId'] as String?;
              if (messageId != null) _seenMsgIds.add(messageId);
              setState(() => _isSending = false);
            }
          },
        );
      } else {
        // Path B: REST API fallback (used when socket is offline)
        // POST /games/:gameId/chat  → { success, message, data: ChatMessageDTO }
        // Where ChatMessageDTO = { _id, senderId, senderName, senderAvatar, text, type, createdAt }
        final api = ref.read(apiClientProvider);
        final resp = await api.post(
          '/games/${widget.game.id}/chat',
          data: {'content': content},
        );
        final body = resp.data as Map<String, dynamic>;
        // The returned message DTO is directly in body['data']
        final msgData = (body['data'] as Map<String, dynamic>?) ?? {};
        
        final msgId = GameEntity.normalize(msgData['_id'] ?? msgData['id']);
        final serverTime = DateTime.tryParse(msgData['createdAt'] as String? ?? '') ?? DateTime.now();

        if (mounted) {
          setState(() {
            // Safety: if socket already echoed and added this message, just remove temp
            final exists = msgId.isNotEmpty && _messages.any((m) => m.id == msgId);
            
            final idx = _messages.indexWhere((m) => m.tempId == tempId);
            if (idx != -1) {
              if (exists) {
                // Socket already added it — remove our optimistic copy
                _messages.removeAt(idx);
              } else {
                // Replace optimistic bubble with confirmed server message
                if (msgId.isNotEmpty) _seenMsgIds.add(msgId);
                _messages[idx] = _ChatMsg(
                  id: msgId.isNotEmpty ? msgId : null,
                  content: content,
                  senderName: 'You',
                  senderId: _myUserId,
                  timestamp: serverTime,
                );
              }
            }
            _isSending = false;
          });
        }
      }
    } catch (e) {
      _handleSendFailure(tempId, null);
    }
  }

  void _handleSendFailure(String tempId, String? error) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.tempId == tempId);
      _pendingTempIds.remove(tempId);
      _isSending = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Failed to send message. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game'),
        content: const Text(
            'Are you sure you want to delete this game? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _deleteGameFromChat();
    }
  }

  Future<void> _deleteGameFromChat() async {
    try {
      final ok = await ref.read(gameProvider.notifier).deleteGame(widget.game.id);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context); // Go back after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game deleted successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(gameProvider).error ?? 'Failed to delete game'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _goToDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailPage(
          gameId: widget.game.id,
          preloadedGame: widget.game,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_socket != null) {
      _socket!.emit('leave:game', widget.game.id);
      _socket!.off('chat:message');
      _socket!.off('connect');
      _socket!.off('disconnect');
      _socket!.off('game:player:joined');
      _socket!.off('game:player:left');
    }
    // Remove the room from the community chat section too
    ref.read(chatProvider.notifier).leaveRoom(widget.game.id);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch auth providers so we update _myUserId if it wasn't available on init
    final auth = ref.watch(authNotifierProvider);
    final viewModel = ref.watch(authViewModelProvider);
    final freshId = GameEntity.normalize(auth.user?.userId ?? viewModel.user?.userId ?? '');
    
    // Update _myUserId if auth providers now have the ID but we didn't on init
    if (freshId.isNotEmpty && _myUserId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _myUserId = freshId);
      });
    }
    // Use _myUserId (from secure storage) as primary source; fallback to providers
    final myCurrentId = _myUserId.isNotEmpty ? _myUserId : freshId;
    
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: BackButtonWidget(), // Removed 'Back' label to fix overflow
        ),
        leadingWidth: 70, // Reduced from 100 since label is gone
        title: Row(
          children: [
            // Game Image
            if (widget.game.imageUrl != null)
              GestureDetector(
                onTap: _goToDetails,
                child: ClipRRect(
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
                ),
              )
            else
              GestureDetector(
                onTap: _goToDetails,
                child: Container(
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
              ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _goToDetails,
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
                        Text(
                          '$_currentPlayerCount ${_currentPlayerCount == 1 ? 'player' : 'players'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
            onPressed: _goToDetails,
            tooltip: 'Game Details',
          ),
          // Delete button (creator only)
          if (widget.game.isCreator(myCurrentId))
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _confirmDelete,
              tooltip: 'Delete Game',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Message list begins immediately without offline banners

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
                        // +1 item at top for the "loading more" indicator
                        itemCount: _messages.length + (_isLoadingMore || _hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          // First item: pagination indicator
                          if ((_isLoadingMore || _hasMore) && i == 0) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: _isLoadingMore
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : TextButton.icon(
                                        onPressed: _loadMore,
                                        icon: const Icon(Icons.expand_less_rounded, size: 18),
                                        label: const Text('Load older messages'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: cs.onSurfaceVariant,
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                              ),
                            );
                          }
                          final msgIdx = i - (_isLoadingMore || _hasMore ? 1 : 0);
                          return _MessageBubble(msg: _messages[msgIdx], myId: myCurrentId);
                        },
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
                  _isSending
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
                          onPressed: _canSend ? () => _sendMessage() : null,
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
    this.isSystem = false,
    this.avatarUrl,
  });
  final String? id;
  final String? tempId;
  final String content;
  final String senderName;
  final String senderId;
  final DateTime timestamp;
  final bool isSystem;
  final String? avatarUrl;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg, required this.myId});
  final _ChatMsg msg;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate if this is our own message dynamically.
    final String cleanSenderId = GameEntity.normalize(msg.senderId);
    final String cleanMyId = GameEntity.normalize(myId);
    
    // CORE RULE: isMe = senderId == currentUserId
    // Never use senderName == 'you' as a fallback — it can misalign messages
    // from users whose display name happens to be 'You'.
    final bool isOwnId = !msg.isSystem &&
        cleanMyId.isNotEmpty &&
        cleanSenderId.isNotEmpty &&
        cleanSenderId == cleanMyId;

    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ),
        ),
      );
    }

    final isPending = msg.id == null;
    final borderRadius = isOwnId
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          );

    // Avatar widget for non-own messages
    Widget avatarWidget = CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: msg.avatarUrl != null && msg.avatarUrl!.isNotEmpty
          ? NetworkImage(msg.avatarUrl!)
          : null,
      child: msg.avatarUrl == null || msg.avatarUrl!.isEmpty
          ? Text(
              msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isOwnId ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar on left for others
          if (!isOwnId) ...[avatarWidget, const SizedBox(width: 8)],

          Expanded(
            child: Align(
              alignment: isOwnId ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment:
                    isOwnId ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name (only for others)
                  if (!isOwnId)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textTertiary : AppColors.textSecondary,
                        ),
                      ),
                    ),

                  // Message Text Bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOwnId
                          ? (isPending ? AppColors.primaryWithOpacity(0.7) : AppColors.primary)
                          : (isDark ? AppColors.cardDark : AppColors.surfaceLight),
                      borderRadius: borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        color: isOwnId ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),

                  // Timestamp & Status
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${msg.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${msg.timestamp.toLocal().minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        if (isOwnId && isPending) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.schedule_rounded, size: 10, color: Colors.blueGrey),
                        ],
                      ],
                    ),
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

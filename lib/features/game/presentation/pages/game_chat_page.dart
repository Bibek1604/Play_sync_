import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/app/theme/app_colors.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/presentation/providers/chat_provider.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_providers.dart';
import 'package:play_sync_new/features/game/presentation/providers/game_realtime_provider.dart';
import 'package:play_sync_new/features/game/presentation/providers/joined_games_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/chat_panel.dart';
import 'package:play_sync_new/features/chat/presentation/providers/chat_preview_provider.dart';

/// Game Chat Page
///
/// Real-time group chat for a specific game.
/// Respects backend game status — blocks chat for ended/cancelled games.
class GameChatPage extends ConsumerStatefulWidget {
  final String gameId;

  const GameChatPage({
    super.key,
    required this.gameId,
  });

  @override
  ConsumerState<GameChatPage> createState() => _GameChatPageState();
}

class _GameChatPageState extends ConsumerState<GameChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.gameId));
    final gameState = ref.watch(gameRealtimeProvider(widget.gameId));
    final currentUser = ref.watch(authNotifierProvider).user;
    final currentUserId = currentUser?.userId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final game = gameState.game;
    final isGameOver = game != null &&
        (game.status == GameStatus.ended ||
            game.status == GameStatus.cancelled);
    final isCreator = game?.creatorId == currentUserId && currentUserId.isNotEmpty;
    final isParticipant =
        game?.participants.any((p) => p.id == currentUserId) ?? false;
    final canAccessChat = isCreator || isParticipant;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundPrimaryDark : const Color(0xFFF6FBF9),
      appBar: _buildAppBar(context, game, isCreator, isDark),
      body: Column(
        children: [
          // 📢 Real-time notification banner
          if (gameState.recentNotifications.isNotEmpty)
            _NotificationBanner(
              notifications: gameState.recentNotifications,
              onDismiss: () => ref
                  .read(gameRealtimeProvider(widget.gameId).notifier)
                  .clearNotifications(),
            ),

          // 🔒 Game over banner
          if (isGameOver)
            _GameOverBanner(game: game, isDark: isDark),

          // Content
          Expanded(
            child: _buildBody(
              context,
              chatState: chatState,
              gameState: gameState,
              currentUserId: currentUserId,
              canAccessChat: canAccessChat,
              isGameOver: isGameOver,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(
    BuildContext context,
    Game? game,
    bool isCreator,
    bool isDark,
  ) {
    final socketConnected =
        ref.watch(socketServiceProvider).isConnected;

    return AppBar(
      backgroundColor:
          isDark ? AppColors.backgroundSecondaryDark : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            game?.title ?? 'Game Chat',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          if (game != null)
            Text(
              '${game.currentPlayers}/${game.maxPlayers} players · '
              '${_statusLabel(game.status)}',
              style: TextStyle(
                fontSize: 12,
                color: _statusColor(game.status),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        // Socket status indicator
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: socketConnected ? 'Connected' : 'Disconnected',
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
              decoration: BoxDecoration(
                color: socketConnected ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // Creator only: delete game
        if (isCreator)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete Game',
            onPressed: () => _confirmDeleteGame(context),
          ),

        // Leave game
        if (game != null &&
            (game.status == GameStatus.open ||
                game.status == GameStatus.full))
          IconButton(
            icon: Icon(
              Icons.exit_to_app_rounded,
              color: isDark ? AppColors.errorDark : AppColors.errorLight,
            ),
            tooltip: 'Leave Game',
            onPressed: () => _confirmLeaveGame(context),
          ),

        const SizedBox(width: 4),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context, {
    required ChatState chatState,
    required GameRealtimeState gameState,
    required String currentUserId,
    required bool canAccessChat,
    required bool isGameOver,
    required bool isDark,
  }) {
    // Loading game
    if (gameState.isLoading && gameState.game == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      );
    }

    // Error loading game
    if (gameState.error != null && gameState.game == null) {
      return _ErrorView(
        error: gameState.error!,
        onRetry: () =>
            ref.read(gameRealtimeProvider(widget.gameId).notifier).loadGame(),
      );
    }

    // Access barrier: user not joined and not creator
    if (!canAccessChat && gameState.game != null && !isGameOver) {
      return _AccessDeniedView(isDark: isDark);
    }

    // Game over: show history but no input
    if (isGameOver) {
      return ChatPanel(
        messages: chatState.messages,
        controller: _messageController,
        onSendMessage: _sendMessage,
        isSending: false,
        isDisabled: true,
        currentUserId: currentUserId,
      );
    }

    // Normal chat
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      );
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return _ErrorView(error: chatState.error!, onRetry: () {});
    }

    return ChatPanel(
      messages: chatState.messages,
      controller: _messageController,
      onSendMessage: _sendMessage,
      isSending: chatState.isSending,
      isDisabled: false,
      currentUserId: currentUserId,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────

  void _sendMessage() {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    ref.read(chatProvider(widget.gameId).notifier).sendMessage(msg);
    _messageController.clear();
  }

  Future<void> _confirmLeaveGame(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.exit_to_app_rounded,
                  color: AppColors.errorLight, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Leave Game'),
          ],
        ),
        content: const Text(
          'Are you sure you want to leave this game?\n'
          'You will lose access to the chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(leaveGameUseCaseProvider).call(widget.gameId);

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      // Remove from joined games list & refresh chat previews
      ref.read(joinedGamesProvider.notifier).removeGame(widget.gameId);
      ref.read(chatPreviewProvider.notifier).load();

      Navigator.pop(context); // go back to chat list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have left the game.'),
            backgroundColor: AppColors.emerald500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave game: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteGame(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Game'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this game?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(deleteGameUseCaseProvider).call(widget.gameId);

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading

      // Remove from state
      ref.read(joinedGamesProvider.notifier).removeGame(widget.gameId);
      ref.read(chatPreviewProvider.notifier).load();

      Navigator.pop(context); // go back

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Game deleted successfully.'),
            backgroundColor: AppColors.emerald500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _statusLabel(GameStatus status) {
    switch (status) {
      case GameStatus.open:
        return 'Open';
      case GameStatus.full:
        return 'Full';
      case GameStatus.ended:
        return 'Ended';
      case GameStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(GameStatus status) {
    switch (status) {
      case GameStatus.open:
        return AppColors.emerald500;
      case GameStatus.full:
        return AppColors.statusWarning;
      case GameStatus.ended:
        return AppColors.textSecondaryLight;
      case GameStatus.cancelled:
        return AppColors.errorLight;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game Over Banner
// ─────────────────────────────────────────────────────────────────────────────

class _GameOverBanner extends StatelessWidget {
  final Game game;
  final bool isDark;

  const _GameOverBanner({required this.game, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isEnded = game.status == GameStatus.ended;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEnded
              ? [
                  AppColors.textSecondaryLight.withOpacity(0.15),
                  AppColors.textTertiaryLight.withOpacity(0.1),
                ]
              : [
                  AppColors.errorLight.withOpacity(0.15),
                  AppColors.errorLight.withOpacity(0.08),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isEnded
                ? AppColors.textSecondaryLight.withOpacity(0.3)
                : AppColors.errorLight.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEnded ? Icons.flag_rounded : Icons.cancel_rounded,
            color: isEnded
                ? AppColors.textSecondaryLight
                : AppColors.errorLight,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            isEnded
                ? 'Game has ended — chat is now read-only.'
                : 'Game was cancelled — chat is now read-only.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Banner
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationBanner extends StatelessWidget {
  final List<String> notifications;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.notifications,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.emerald900.withOpacity(0.25)
            : const Color(0xFFE8F8F2),
        border: Border(
          bottom: BorderSide(
            color: AppColors.emerald500.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.emerald500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: notifications.take(2).map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    n,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Access Denied View
// ─────────────────────────────────────────────────────────────────────────────

class _AccessDeniedView extends StatelessWidget {
  final bool isDark;

  const _AccessDeniedView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.textSecondaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chat Access Blocked',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You must join this game to access the chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to load chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


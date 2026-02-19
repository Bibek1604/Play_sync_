import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_sync_new/features/auth/presentation/providers/auth_notifier.dart';
import 'package:play_sync_new/features/game/domain/entities/game.dart';
import 'package:play_sync_new/features/game/presentation/providers/current_game_provider.dart';
import 'package:play_sync_new/features/game/presentation/widgets/player_list_panel.dart';
import 'package:play_sync_new/features/game/presentation/widgets/chat_panel.dart';
import 'package:play_sync_new/shared/widgets/widgets.dart';
import 'package:play_sync_new/core/theme/app_spacing.dart';
import 'package:play_sync_new/core/theme/app_typography.dart';
import 'package:play_sync_new/core/theme/app_colors.dart';
import 'package:play_sync_new/core/services/sound_manager.dart';

/// Game Hub Screen
/// 
/// Main game room with players and chat
class GameHubScreen extends ConsumerStatefulWidget {
  const GameHubScreen({super.key});

  @override
  ConsumerState<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends ConsumerState<GameHubScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(currentGameProvider);
    final currentUserId =
        ref.watch(authNotifierProvider).user?.userId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (gameState.game == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final game = gameState.game!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.backgroundPrimaryDark, AppColors.backgroundSecondaryDark]
                : [AppColors.backgroundPrimaryLight, AppColors.backgroundSecondaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, game.name),
              
              // Main Content
              Expanded(
                child: Row(
                  children: [
                    // Players Panel (Left)
                    Expanded(
                      flex: 1,
                      child: PlayerListPanel(
                        players: game.players,
                        maxPlayers: game.maxPlayers,
                        hostId: game.hostId,
                      ),
                    ),
                    
                    // Chat Panel (Right)
                    Expanded(
                      flex: 2,
                      child: ChatPanel(
                        messages: gameState.chatMessages,
                        controller: _chatController,
                        onSendMessage: _sendMessage,
                        isSending: gameState.isSendingMessage,
                        currentUserId: currentUserId,
                        isDisabled: gameState.game?.status == GameStatus.ended ||
                            gameState.game?.status == GameStatus.cancelled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String gameName) {
    return GlassCard(
      margin: AppSpacing.paddingMD,
      child: Row(
        children: [
          IconButton(
            onPressed: () => _leaveGame(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.emerald500,
          ),
          AppSpacing.gapHorizontalMD,
          Expanded(
            child: Text(
              gameName,
              style: AppTypography.h2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppBorderRadius.chip,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.gapHorizontalSM,
                Text(
                  'LIVE',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    _chatController.clear();
    await ref.read(currentGameProvider.notifier).sendMessage(message);
    SoundManager.instance.playChatMessage();
  }

  Future<void> _leaveGame(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game'),
        content: const Text('Are you sure you want to leave this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(currentGameProvider.notifier).leaveGame();
      SoundManager.instance.playLeaveGame();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}

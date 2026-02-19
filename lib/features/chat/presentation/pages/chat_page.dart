import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../features/game/presentation/providers/joined_games_provider.dart';
import '../../../../features/game/domain/entities/game.dart';
import '../providers/chat_preview_provider.dart';

/// Chat Page — Game Group Selection Screen
///
/// Shows ONLY active game groups the user has joined or created.
/// No friends list, no unrelated sections — 100% backend-driven.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(joinedGamesProvider.notifier).loadJoinedGames();
      ref.read(chatPreviewProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundPrimaryDark : const Color(0xFFF6FBF9),
      drawer: const AppDrawer(),
      appBar: _buildAppBar(context, isDark),
      body: _GameGroupList(isDark: isDark),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          isDark ? AppColors.backgroundSecondaryDark : Colors.white,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emerald500, AppColors.teal500],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'Game Chats',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () {
            ref.read(joinedGamesProvider.notifier).loadJoinedGames();
            ref.read(chatPreviewProvider.notifier).load();
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active game groups list
// ─────────────────────────────────────────────────────────────────────────────

class _GameGroupList extends ConsumerWidget {
  final bool isDark;

  const _GameGroupList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedState = ref.watch(joinedGamesProvider);
    final previewState = ref.watch(chatPreviewProvider);

    if (joinedState.isLoading && joinedState.games.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      );
    }

    if (joinedState.error != null && joinedState.games.isEmpty) {
      return _ErrorView(
        error: joinedState.error!,
        onRetry: () {
          ref.read(joinedGamesProvider.notifier).loadJoinedGames();
          ref.read(chatPreviewProvider.notifier).load();
        },
      );
    }

    // Only OPEN or FULL games have active chat
    final activeGames = joinedState.activeChatGames;

    final previewMap = {
      for (final p in previewState.previews) p.gameId: p,
    };

    if (activeGames.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return RefreshIndicator(
      color: AppColors.emerald500,
      onRefresh: () async {
        await ref.read(joinedGamesProvider.notifier).loadJoinedGames();
        await ref.read(chatPreviewProvider.notifier).load();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: activeGames.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 80,
          color: isDark ? AppColors.dividerDark : const Color(0xFFE8F5F0),
        ),
        itemBuilder: (context, index) {
          final game = activeGames[index];
          final preview = previewMap[game.id];
          return _GameGroupTile(
            game: game,
            lastMessage: preview?.lastMessage,
            lastMessageAt: preview?.lastMessageAt,
            unreadCount: preview?.unreadCount ?? 0,
            isDark: isDark,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.chat,
              arguments: {'gameId': game.id},
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group tile
// ─────────────────────────────────────────────────────────────────────────────

class _GameGroupTile extends StatelessWidget {
  final Game game;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isDark;
  final VoidCallback onTap;

  const _GameGroupTile({
    required this.game,
    required this.isDark,
    required this.onTap,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = lastMessageAt != null ? _formatTime(lastMessageAt!) : '';
    final subtitle = lastMessage ?? 'Tap to open chat';
    final hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _GroupAvatar(game: game),
      title: Text(
        game.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: hasUnread
                      ? AppColors.emerald600
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight:
                      hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    game.status == GameStatus.full ? 'FULL' : 'LIVE',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.emerald500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(height: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emerald500, AppColors.teal500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group avatar
// ─────────────────────────────────────────────────────────────────────────────

class _GroupAvatar extends StatelessWidget {
  final Game game;

  const _GroupAvatar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald400, AppColors.teal400],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: game.imageUrl != null && game.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                game.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(title: game.title),
              ),
            )
          : _Initials(title: game.title),
    );
  }
}

class _Initials extends StatelessWidget {
  final String title;

  const _Initials({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title.isNotEmpty ? title[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.emerald500
                    .withOpacity(isDark ? 0.1 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.emerald500,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Active Game Chats',
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
              'Join a game to start chatting\nwith other players in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.onlineGames),
              icon: const Icon(Icons.sports_esports_rounded),
              label: const Text('Browse Games'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to load chats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondaryLight),
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

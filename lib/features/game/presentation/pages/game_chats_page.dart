import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/game_notifier.dart';
import '../widgets/game_chat_preview_card.dart';

class GameChatsPage extends ConsumerStatefulWidget {
  const GameChatsPage({super.key});

  @override
  ConsumerState<GameChatsPage> createState() => _GameChatsPageState();
}

class _GameChatsPageState extends ConsumerState<GameChatsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load joined games on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).fetchMyJoinedGames();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh games when returning from background
    if (state == AppLifecycleState.resumed && mounted) {
      Future.microtask(() {
        if (mounted) {
          ref.read(gameProvider.notifier).fetchMyJoinedGames();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = authState.user?.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get only joined games (excluding created games)
    final joinedGames = gameState.myJoinedGames;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        title: Text(
          'Game Chats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () async {
              await ref.read(gameProvider.notifier).fetchMyJoinedGames();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(gameProvider.notifier).fetchMyJoinedGames();
        },
        child: joinedGames.isEmpty
            ? _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: joinedGames.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) {
                  final game = joinedGames[index];
                  return GameChatPreviewCard(
                    game: game,
                    currentUserId: currentUserId,
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Game Chats Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Join a game to start chatting with other players!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/online-games'),
                icon: const Icon(Icons.public_rounded),
                label: const Text('Browse Games'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

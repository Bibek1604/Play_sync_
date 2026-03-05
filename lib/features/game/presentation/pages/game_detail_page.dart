import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:cached_network_image/cached_network_image.dart";
import "../../../../core/constants/app_colors.dart";
import "../../domain/entities/game_entity.dart";
import "../providers/game_notifier.dart";
import "../../../auth/presentation/providers/auth_notifier.dart";
import "../../../game_chat/game_chat.dart";

class GameDetailPage extends ConsumerStatefulWidget {
  final String gameId;
  final GameEntity? preloadedGame;
  const GameDetailPage({super.key, required this.gameId, this.preloadedGame});

  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  GameEntity? _game;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchGame();
  }

  Future<void> _fetchGame() async {
    setState(() => _loading = _game == null);
    try {
      final game = await ref.read(gameProvider.notifier).fetchGameById(widget.gameId, forceRefresh: true);
      if (mounted) setState(() { _game = game; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final game = _game ?? widget.preloadedGame;

    if (_loading && game == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (game == null) return const Scaffold(body: Center(child: Text("Game not found")));

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (game.imageUrl != null && game.imageUrl!.isNotEmpty)
                    CachedNetworkImage(imageUrl: game.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(color: AppColors.primary),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(6)),
                          child: Text(game.sport.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(game.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoSection(
                  title: "Match Details",
                  children: [
                    _IconDetail(icon: Icons.calendar_today_rounded, label: "Date", value: game.startTime != null ? DateFormat("MMM d, yyyy").format(game.startTime!) : "TBD"),
                    _IconDetail(icon: Icons.access_time_rounded, label: "Time", value: game.startTime != null ? DateFormat("hh:mm a").format(game.startTime!) : "TBD"),
                    _IconDetail(icon: Icons.location_on_rounded, label: "Status", value: game.status.name),
                  ],
                ),
                const SizedBox(height: 24),
                const Text("About the Game", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(game.description.isNotEmpty ? game.description : "No description provided for this session.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.6)),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => GameChatRoomPage(gameId: game.id, gameTitle: game.title)));
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("OPEN SESSION CHAT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _IconDetail extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _IconDetail({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ],
      ),
    );
  }
}

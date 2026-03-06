import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../game/domain/entities/game_entity.dart';
import '../../../game/presentation/pages/game_detail_page.dart';

class GameTileWidget extends StatefulWidget {
  final GameEntity game;
  final String? currentUserId;
  final VoidCallback? onDelete;

  const GameTileWidget({
    super.key,
    required this.game,
    this.currentUserId,
    this.onDelete,
  });

  @override
  State<GameTileWidget> createState() => _GameTileWidgetState();
}

class _GameTileWidgetState extends State<GameTileWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _statusColor() {
    return switch (widget.game.status) {
      GameStatus.OPEN => AppColors.success,
      GameStatus.FULL => AppColors.warning,
      GameStatus.ENDED => AppColors.textTertiary,
      GameStatus.CANCELLED => AppColors.error,
    };
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final bool isJoined = widget.game.isParticipant(widget.currentUserId ?? '') || 
                         widget.game.isCreator(widget.currentUserId ?? '');

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        // If not joined, they should only see the detail page to join, not "view game" depth
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameDetailPage(gameId: widget.game.id, preloadedGame: widget.game),
          ),
        );
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.45, // Keep width decreased, not length
          margin: const EdgeInsets.only(bottom: AppSpacing.space16, right: AppSpacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radius20),
            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: statusColor.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Ensure it only takes needed height
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    _GamePreviewImage(game: widget.game),
                    if (isJoined)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 10),
                        ),
                      ),
                    // Show a little icon to indicate if game is offline or online
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.game.isOffline ? Icons.location_on_rounded : Icons.public_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(widget.game.isOffline ? 'Offline' : 'Online', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Compressed vertical padding slightly
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Keep this min, but let row content not break into multiple lines
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.game.sport.toLowerCase().contains('football') ? Icons.sports_soccer_rounded :
                          widget.game.sport.toLowerCase().contains('basketball') ? Icons.sports_basketball_rounded :
                          widget.game.sport.toLowerCase().contains('tennis') ? Icons.sports_tennis_rounded :
                          Icons.sports_esports_rounded, 
                          size: 14, 
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.game.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Use a Wrap or Flexible row to prevent any text scaling overflows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.game.status.name,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.group_rounded, size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.game.currentPlayers}/${widget.game.maxPlayers}',
                                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        if (widget.game.startTime != null)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_rounded, size: 10, color: AppColors.textTertiary),
                                const SizedBox(width: 3),
                                Text(
                                  DateFormat('MMM d').format(widget.game.startTime!),
                                  style: const TextStyle(
                                    fontSize: 10, // Larger text
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    // Action Button inside Tile
                    const SizedBox(height: 12), // Decreased gap Above button to push it down slightly less
                    if (isJoined)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10), // Slimmer border radius for rectangular look
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameDetailPage(
                                gameId: widget.game.id,
                                preloadedGame: widget.game,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.visibility_rounded, size: 16), // Bigger icon fit for thick button
                          label: const Text('View Match', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis), // Bump font size
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14), // Thicker button
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameDetailPage(
                                gameId: widget.game.id,
                                preloadedGame: widget.game,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Join Match', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14), // Thicker button
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                          ),
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
}

class _GamePreviewImage extends StatelessWidget {
  final GameEntity game;
  const _GamePreviewImage({required this.game});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radius20)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: SizedBox(
          width: double.infinity,
          child: game.imageUrl != null && game.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: game.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, _, __) => _TileImagePlaceholder(game: game),
                )
              : _TileImagePlaceholder(game: game),
        ),
      ),
    );
  }
}

class _TileImagePlaceholder extends StatelessWidget {
  final GameEntity game;
  const _TileImagePlaceholder({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.info.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 38, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              game.sport.isEmpty ? 'Game cover' : '${game.sport} cover',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

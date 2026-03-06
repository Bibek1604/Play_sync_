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
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSubtle, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 2.1 / 1, // Shorter height
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _GamePreviewImage(game: widget.game),
                    // Elegant Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isJoined)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Joined', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    // Premium Floating Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.game.isOffline ? Icons.location_on_rounded : Icons.public_rounded,
                              color: widget.game.isOffline ? AppColors.primary : AppColors.secondary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.game.isOffline ? 'Local' : 'Remote',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), // Tightened vertical padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.game.sport.toLowerCase().contains('football') ? Icons.sports_soccer_rounded :
                            widget.game.sport.toLowerCase().contains('basketball') ? Icons.sports_basketball_rounded :
                            widget.game.sport.toLowerCase().contains('tennis') ? Icons.sports_tennis_rounded :
                            Icons.sports_esports_rounded, 
                            size: 20, 
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.game.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14, // Slightly smaller title
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.game.sport,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Tightened gap
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailLabel(
                          icon: Icons.group_rounded,
                          label: '${widget.game.currentPlayers}/${widget.game.maxPlayers} Players',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            widget.game.status.name,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6), // Tightened gap
                    if (widget.game.startTime != null)
                      _DetailLabel(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('EEEE, MMM d · hh:mm a').format(widget.game.startTime!),
                      ),
                    const SizedBox(height: 2), // Tightest possible gap
                    PrimaryButton(
                      label: isJoined ? 'View Match' : 'Join Match',
                      icon: isJoined ? Icons.visibility_rounded : Icons.login_rounded,
                      height: 40, // More compact button height
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameDetailPage(
                            gameId: widget.game.id,
                            preloadedGame: widget.game,
                          ),
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

class _DetailLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GamePreviewImage extends StatelessWidget {
  final GameEntity game;
  const _GamePreviewImage({required this.game});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: AspectRatio(
        aspectRatio: 16 / 10,
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
            AppColors.primary.withOpacity(0.14),
            AppColors.info.withOpacity(0.08),
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

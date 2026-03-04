import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
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
    final isCreator = widget.currentUserId != null && widget.game.isCreator(widget.currentUserId!);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameDetailPage(gameId: widget.game.id, preloadedGame: widget.game),
        ),
      ),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space16),
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              children: [
                // Sport Icon / Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radius16),
                  ),
                  child: const Icon(Icons.sports_soccer_rounded,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: AppSpacing.space16),
                
                // Game Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.game.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 10, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.game.currentPlayers}/${widget.game.maxPlayers}',
                                  style: const TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.game.sport,
                            style: const TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      if (widget.game.startTime != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('EEEE, MMM dd • hh:mm a').format(widget.game.startTime!),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary.withValues(alpha: 0.6),
                              letterSpacing: 0.2),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status & Action
                const SizedBox(width: AppSpacing.space12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radius10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Text(
                        widget.game.status.name,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    if (isCreator && widget.onDelete != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 18),
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.arrow_forward_ios_rounded, 
                          color: AppColors.primary, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

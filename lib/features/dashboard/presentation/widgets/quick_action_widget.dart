import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../app/routes/app_routes.dart';

class QuickActionWidget extends StatelessWidget {
  const QuickActionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Reuse the same logic as DashboardPage for consistency
    final double sectionPadding = size.width > 600 ? size.width * 0.1 : AppSpacing.space20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sectionPadding),  
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _ViewAllButton(onTap: () => Navigator.pushNamed(context, AppRoutes.gameHistory)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space24),
        
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            const double spacing = AppSpacing.space16;
            final int crossAxisCount = width > 600 ? 4 : 2;
            
            // Adjust ratio based on width
            final double cardRatio = width < 380 ? 0.95 : 1.15;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: sectionPadding),
              child: GridView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: cardRatio,
                ),
                children: [
                  _AnimatedActionCard(
                    icon: Icons.wifi_off_rounded,
                    title: 'Offline',
                    subtitle: 'Local Match',
                    baseColor: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.offlineGames),
                  ),
                  _AnimatedActionCard(
                    icon: Icons.public_rounded,
                    title: 'Online',
                    subtitle: 'Remote Play',
                    baseColor: AppColors.info,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.onlineGames),
                  ),
                  _AnimatedActionCard(
                    icon: Icons.auto_graph_rounded,
                    title: 'Stats',
                    subtitle: 'Rankings',
                    baseColor: AppColors.warning,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.rankings),
                  ),
                  _AnimatedActionCard(
                    icon: Icons.settings_suggest_rounded,
                    title: 'Adjust',
                    subtitle: 'Settings',
                    baseColor: AppColors.success,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.gameHistory),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AnimatedActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color baseColor;
  final VoidCallback onTap;

  const _AnimatedActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.baseColor,
    required this.onTap,
  });

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radius24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.baseColor.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: widget.baseColor.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 1,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radius16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.baseColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: widget.baseColor, size: 22),
                ),
                const Spacer(),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radius12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'History',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 10),
            ],
          ),
        ),
      ),
    );
  }
}

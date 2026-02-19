import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_step.dart';

/// Renders the visual illustration slot for an onboarding step.
/// Falls back to an icon placeholder when the asset is unavailable.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingIllustration({super.key, required this.step});

  static const _fallbackIcons = [
    Icons.sports_esports,
    Icons.search,
    Icons.leaderboard,
    Icons.chat_bubble,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.5),
            cs.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: _buildContent(cs),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    // Try loading the image asset; fall back to icon on error.
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        step.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            _fallbackIcons[step.index.clamp(0, _fallbackIcons.length - 1)],
            size: 120,
            color: cs.primary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

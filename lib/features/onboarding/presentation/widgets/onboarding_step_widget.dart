import 'package:flutter/material.dart';
import '../../domain/entities/onboarding_step.dart';
import 'onboarding_illustration.dart';

/// Full content widget for a single onboarding step — illustration + text.
class OnboardingStepWidget extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingStepWidget({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          OnboardingIllustration(step: step),
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              step.title,
              key: ValueKey('title-${step.index}'),
              textAlign: TextAlign.center,
              style: tt.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              step.description,
              key: ValueKey('desc-${step.index}'),
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Shown after all onboarding steps are completed.
class OnboardingDonePage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OnboardingDonePage({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success animation placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline_rounded, size: 72, color: cs.primary),
              ),
              const SizedBox(height: 32),
              Text(
                "You're all set!",
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Time to jump in, find your game, and start playing.',
                textAlign: TextAlign.center,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onGetStarted,
                  child: const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onGetStarted,
                child: const Text('I already have an account'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_notifier.dart';

/// Entry splash/welcome screen shown before the onboarding steps.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary, cs.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Logo/icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(Icons.sports_esports_rounded, size: 64, color: cs.onPrimary),
                ),
                const SizedBox(height: 32),
                Text(
                  'PlaySync',
                  style: tt.displaySmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Play together. Win together.',
                  textAlign: TextAlign.center,
                  style: tt.titleMedium?.copyWith(color: cs.onPrimary.withOpacity(0.85)),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.onPrimary,
                      foregroundColor: cs.primary,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const _OnboardingEntryRouter()),
                      );
                    },
                    child: const Text("Let's Go", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Router widget that shows onboarding; pop to login after completion.
class _OnboardingEntryRouter extends ConsumerWidget {
  const _OnboardingEntryRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(onboardingProvider.select((s) => s.isCompleted), (_, done) {
      if (done) {
        Navigator.of(context).pushNamedAndRemoveUntil('/register', (_) => false);
      }
    });
    // Import inline to avoid circular — in real usage import OnboardingPage
    return const Placeholder(); // replaced by OnboardingPage in main routing
  }
}

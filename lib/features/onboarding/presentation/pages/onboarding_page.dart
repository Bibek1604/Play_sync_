import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/onboarding_step.dart';
import '../providers/onboarding_notifier.dart';
import '../widgets/onboarding_step_widget.dart';
import '../widgets/onboarding_dot_indicator.dart';
import '../widgets/skip_button.dart';

/// Main onboarding PageView with bottom navigation controls.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    // Sync page controller when notifier index changes.
    ref.listen(onboardingProvider.select((s) => s.currentIndex), (_, next) {
      if (_controller.hasClients && _controller.page?.round() != next) {
        _animateTo(next);
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: state.isLast
                    ? const SizedBox(height: 40)
                    : SkipButton(onSkip: notifier.skip),
              ),
            ),

            // Step PageView
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: kOnboardingSteps.length,
                onPageChanged: notifier.goTo,
                itemBuilder: (_, i) => OnboardingStepWidget(step: kOnboardingSteps[i]),
              ),
            ),

            // Dots + Next/Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(
                children: [
                  OnboardingDotIndicator(
                    count: kOnboardingSteps.length,
                    currentIndex: state.currentIndex,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: notifier.next,
                      child: Text(state.isLast ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

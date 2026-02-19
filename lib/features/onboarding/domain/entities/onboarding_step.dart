/// Represents a single onboarding step with content and metadata.
class OnboardingStep {
  final int index;
  final String title;
  final String description;
  final String assetPath;  // Lottie or image asset path
  final String? actionLabel;

  const OnboardingStep({
    required this.index,
    required this.title,
    required this.description,
    required this.assetPath,
    this.actionLabel,
  });

  @override
  String toString() => 'OnboardingStep($index, "$title")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OnboardingStep && index == other.index;

  @override
  int get hashCode => index.hashCode;
}

/// Static list of pre-defined onboarding steps for PlaySync.
const kOnboardingSteps = [
  OnboardingStep(
    index: 0,
    title: 'Welcome to PlaySync',
    description: 'Your ultimate companion for sports, games, and staying connected with friends.',
    assetPath: 'assets/images/onboarding_welcome.png',
  ),
  OnboardingStep(
    index: 1,
    title: 'Discover Games',
    description: 'Browse hundreds of sports games, join sessions, and track your match history all in one place.',
    assetPath: 'assets/images/onboarding_discover.png',
  ),
  OnboardingStep(
    index: 2,
    title: 'Compete & Climb',
    description: 'Earn points, streak badges, and race up the global leaderboard with friends and rivals.',
    assetPath: 'assets/images/onboarding_leaderboard.png',
  ),
  OnboardingStep(
    index: 3,
    title: 'Chat in Real-Time',
    description: 'Stay connected with your team through instant in-game chat and live notifications.',
    assetPath: 'assets/images/onboarding_chat.png',
    actionLabel: 'Get Started',
  ),
];

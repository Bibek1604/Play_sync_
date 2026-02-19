import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/onboarding_step.dart';

/// State for the onboarding flow.
class OnboardingState {
  final int currentIndex;
  final bool isCompleted;
  final bool isAnimating;

  const OnboardingState({
    this.currentIndex = 0,
    this.isCompleted = false,
    this.isAnimating = false,
  });

  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == kOnboardingSteps.length - 1;

  OnboardingState copyWith({int? currentIndex, bool? isCompleted, bool? isAnimating}) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

/// Manages onboarding step navigation and persistence.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  static const _prefKey = 'onboarding.completed';

  /// Move to the next step; completes if already on last.
  Future<void> next() async {
    if (state.isLast) {
      await complete();
      return;
    }
    state = state.copyWith(currentIndex: state.currentIndex + 1, isAnimating: true);
    await Future.delayed(const Duration(milliseconds: 100));
    state = state.copyWith(isAnimating: false);
  }

  /// Jump directly to a step by index.
  void goTo(int index) {
    assert(index >= 0 && index < kOnboardingSteps.length, 'Index out of range');
    state = state.copyWith(currentIndex: index);
  }

  /// Skip to completion immediately.
  Future<void> skip() async => complete();

  /// Mark onboarding as done and persist the flag.
  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    state = state.copyWith(isCompleted: true);
  }

  /// Check whether onboarding was previously completed.
  static Future<bool> wasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }
}

/// Provider for the onboarding flow state.
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(),
);

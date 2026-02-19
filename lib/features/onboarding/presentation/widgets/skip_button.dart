import 'package:flutter/material.dart';

/// Skip button shown on non-final onboarding steps.
class SkipButton extends StatelessWidget {
  final VoidCallback onSkip;
  final String label;

  const SkipButton({super.key, required this.onSkip, this.label = 'Skip'});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onSkip,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.outline,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

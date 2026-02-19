import 'package:flutter/material.dart';
import 'package:play_sync_new/features/auth/domain/utils/auth_validators.dart';

/// Displays a colour-coded password strength bar with a label.
///
/// Usage:
/// ```dart
/// PasswordStrengthIndicator(password: _passwordController.text)
/// ```
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  static const _colors = [
    Color(0xFFE53E3E), // weak  – red
    Color(0xFFDD6B20), // fair  – orange
    Color(0xFFD69E2E), // good  – yellow
    Color(0xFF38A169), // strong – green
  ];

  @override
  Widget build(BuildContext context) {
    final score = AuthValidators.passwordStrength(password);
    final label = AuthValidators.strengthLabel(score);
    final color = score == 0 ? Colors.grey.shade300 : _colors[score - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < score ? color : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        if (password.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

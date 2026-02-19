import 'package:flutter/material.dart';
import 'package:play_sync_new/features/auth/domain/utils/auth_validators.dart';

/// A pre-styled text field that includes live password-strength feedback.
///
/// Drop-in replacement for any password input in auth forms.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final TextInputAction textInputAction;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.showStrengthIndicator = false,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          validator: widget.validator ?? AuthValidators.validatePassword,
          onChanged: (_) {
            if (widget.showStrengthIndicator) setState(() {});
          },
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (widget.showStrengthIndicator) ...[
          const SizedBox(height: 4),
          _StrengthBar(password: widget.controller.text),
        ],
      ],
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final String password;
  const _StrengthBar({required this.password});

  static const _colors = [
    Color(0xFFE53E3E),
    Color(0xFFDD6B20),
    Color(0xFFD69E2E),
    Color(0xFF38A169),
  ];

  @override
  Widget build(BuildContext context) {
    final score = AuthValidators.passwordStrength(password);
    final color = score == 0 ? Colors.grey.shade300 : _colors[score - 1];
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            height: 3,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < score ? color : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

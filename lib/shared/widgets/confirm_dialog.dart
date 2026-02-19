import 'package:flutter/material.dart';

/// A reusable confirmation dialog.
/// Returns `true` if the user confirms, `false` or `null` if they cancel.
///
/// Usage:
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context,
///   title: 'Delete Game',
///   message: 'This cannot be undone.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor =
        isDestructive ? const Color(0xFFE53E3E) : Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor, size: 22),
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

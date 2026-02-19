import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../../../../shared/theme/app_colors.dart';

/// Color swatch grid for picking accent color.
class AccentColorPicker extends ConsumerWidget {
  const AccentColorPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(accentColorProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AccentColorNotifier.presets.map((color) {
        final selected = color.value == current.value;
        return GestureDetector(
          onTap: () => ref.read(accentColorProvider.notifier).setAccent(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)] : null,
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }
}

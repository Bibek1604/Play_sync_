import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Shows three preview cards for light / dark / system theme modes.
class ThemePreviewCard extends ConsumerWidget {
  const ThemePreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider);

    return Row(
      children: [
        _PreviewTile(
          label: 'Light',
          icon: Icons.light_mode,
          bg: Colors.white,
          fg: Colors.black87,
          isSelected: selected == ThemeMode.light,
          onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
        ),
        const SizedBox(width: 12),
        _PreviewTile(
          label: 'Dark',
          icon: Icons.dark_mode,
          bg: const Color(0xFF1A1A2E),
          fg: Colors.white,
          isSelected: selected == ThemeMode.dark,
          onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
        ),
        const SizedBox(width: 12),
        _PreviewTile(
          label: 'System',
          icon: Icons.brightness_auto,
          bg: Theme.of(context).colorScheme.surfaceContainerHighest,
          fg: Theme.of(context).colorScheme.onSurfaceVariant,
          isSelected: selected == ThemeMode.system,
          onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
        ),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool isSelected;
  final VoidCallback onTap;

  const _PreviewTile({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2.5)
                : Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: fg, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_prefs_provider.dart';
import '../../../../app/theme/app_colors.dart';

class AppSettingsPage extends ConsumerWidget {
  static const routeName = '/app-settings';
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);
    final notifPrefs = ref.watch(notifPrefsProvider);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        children: [
          _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              onChanged: (m) => m != null ? ref.read(themeProvider.notifier).setTheme(m) : null,
              items: ThemeMode.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(_capitalise(m.name))))
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Accent Color'),
            trailing: Wrap(
              spacing: 6,
              children: AccentColorNotifier.presets.map((c) {
                return GestureDetector(
                  onTap: () => ref.read(accentColorProvider.notifier).setAccent(c),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: c,
                    child: c == accent ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          _SectionHeader('Language'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('App Language'),
            subtitle: Text(lang.nativeName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref, lang),
          ),
          const Divider(),
          _SectionHeader('Notifications'),
          ...notifPrefs.toMap().entries.map((e) => SwitchListTile(
            title: Text(_prettyKey(e.key)),
            value: e.value,
            activeThumbColor: AppColors.emerald500,
            onChanged: (_) => ref.read(notifPrefsProvider.notifier).toggle(e.key),
          )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppLanguage current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: kSupportedLanguages.map((l) => ListTile(
          title: Text(l.name),
          subtitle: Text(l.nativeName),
          trailing: l.code == current.code ? const Icon(Icons.check, color: AppColors.emerald500) : null,
          onTap: () {
            ref.read(languageProvider.notifier).setLanguage(l);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  static String _capitalise(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  static String _prettyKey(String key) => key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)!}').trim();
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Static about/info page with app version details.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) => setState(() => _info = info));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.sports_esports, size: 52, color: cs.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('PlaySync', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (_info != null) ...[
            const SizedBox(height: 4),
            Center(child: Text('Version ${_info!.version} (${_info!.buildNumber})', style: tt.bodyMedium)),
          ],
          const SizedBox(height: 32),
          const Divider(),
          _InfoTile(
            icon: Icons.code,
            title: 'Built with Flutter',
            subtitle: 'Cross-platform, fast, delightful',
          ),
          _InfoTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'playsync.app/privacy',
            onTap: () {},
          ),
          _InfoTile(
            icon: Icons.article_outlined,
            title: 'Terms of Service',
            subtitle: 'playsync.app/terms',
            onTap: () {},
          ),
          _InfoTile(
            icon: Icons.mail_outline,
            title: 'Contact Support',
            subtitle: 'support@playsync.app',
            onTap: () {},
          ),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Text('© ${DateTime.now().year} PlaySync. All rights reserved.',
                style: tt.bodySmall?.copyWith(color: cs.outline)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _InfoTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}

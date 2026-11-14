import 'package:flutter/material.dart';

import 'app_env.dart';
import 'l10n/app_localizations.dart';
import 'legal_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.env});

  final AppEnv env;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<AppInfo> _info = widget.env.info();

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return FutureBuilder<AppInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info == null
            ? l.noValue
            : l.aboutVersion(info.version, info.build);
        return Scaffold(
          appBar: AppBar(title: Text(l.aboutTitle)),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.appTitle, style: text.headlineMedium),
                    Text(version, style: text.bodyMedium),
                    const SizedBox(height: 16),
                    Text(l.aboutDescription, style: text.bodyLarge),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(l.termsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(const TermsPage()),
              ),
              ListTile(
                title: Text(l.privacyTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _push(const PrivacyPage()),
              ),
              ListTile(
                title: Text(l.licensesTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l.appTitle,
                  applicationVersion: version,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

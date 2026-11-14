import 'package:flutter/material.dart';

import 'app_env.dart';
import 'l10n/app_localizations.dart';
import 'legal_text.dart';
import 'linked_text.dart';

/// The Terms of Service. With [onAccept], it is the first-launch gate.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key, required this.env, this.onAccept});

  final AppEnv env;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _LegalPage(
      env: env,
      title: l.termsTitle,
      sections: termsSections(l),
      bottom: onAccept == null
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PrivacyPage(env: env),
                    ),
                  ),
                  child: Text(l.privacyTitle),
                ),
                FilledButton(onPressed: onAccept, child: Text(l.accept)),
              ],
            ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, required this.env});

  final AppEnv env;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _LegalPage(
      env: env,
      title: l.privacyTitle,
      sections: privacySections(l),
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({
    required this.env,
    required this.title,
    required this.sections,
    this.bottom,
  });

  final AppEnv env;
  final String title;
  final List<LegalSection> sections;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final (heading, body) in sections) ...[
              Semantics(
                header: true,
                child: Text(heading, style: text.titleMedium),
              ),
              const SizedBox(height: 4),
              LinkedText(body, onOpen: env.openUri, style: text.bodyMedium),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: bottom),
            ),
    );
  }
}

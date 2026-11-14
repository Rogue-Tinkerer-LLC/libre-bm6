import 'package:flutter/material.dart';

import 'app_env.dart';
import 'l10n/app_localizations.dart';

/// The Terms of Service. With [onAccept], it is the first-launch gate.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key, this.onAccept});

  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _LegalPage(
      title: l.termsTitle,
      sections: [
        (l.termsSummaryHeading, l.termsSummary),
        (l.termsLicenseHeading, l.termsLicense),
        (l.termsWarrantyHeading, l.termsWarranty),
        (l.termsLiabilityHeading, l.termsLiability),
        (l.termsIndependentHeading, l.termsIndependent),
        (l.termsAccuracyHeading, l.termsAccuracy),
        (l.termsSafetyHeading, l.termsSafety),
        (l.termsFullLicenseHeading, l.termsFullLicense),
        (l.termsChangesHeading, l.termsChanges),
        (l.termsContactHeading, l.termsContact(issuesUrl)),
      ],
      bottom: onAccept == null
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPage(),
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
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _LegalPage(
      title: l.privacyTitle,
      sections: [
        (l.privacySummaryHeading, l.privacySummary),
        (l.privacyStoredHeading, l.privacyStored),
        (l.privacyNotDoneHeading, l.privacyNotDone),
        (l.privacyBluetoothHeading, l.privacyBluetooth),
        (l.privacyBugReportHeading, l.privacyBugReport),
        (l.privacySourceHeading, l.privacySource),
        (l.privacyChangesHeading, l.privacyChanges),
        (l.privacyContactHeading, l.privacyContact(issuesUrl)),
      ],
    );
  }
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({required this.title, required this.sections, this.bottom});

  final String title;
  final List<(String, String)> sections;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (heading, body) in sections) ...[
            Semantics(
              header: true,
              child: Text(heading, style: text.titleMedium),
            ),
            const SizedBox(height: 4),
            SelectableText(body, style: text.bodyMedium),
            const SizedBox(height: 16),
          ],
        ],
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: bottom),
            ),
    );
  }
}

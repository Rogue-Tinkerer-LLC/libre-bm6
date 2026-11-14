import 'app_env.dart';
import 'l10n/app_localizations.dart';
import 'linked_text.dart';

typedef LegalSection = (String heading, String body);

List<LegalSection> termsSections(AppLocalizations l) => [
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
];

List<LegalSection> privacySections(AppLocalizations l) => [
  (l.privacySummaryHeading, l.privacySummary),
  (l.privacyStoredHeading, l.privacyStored),
  (l.privacyNotDoneHeading, l.privacyNotDone),
  (l.privacyBluetoothHeading, l.privacyBluetooth),
  (l.privacyBugReportHeading, l.privacyBugReport),
  (l.privacySourceHeading, l.privacySource),
  (l.privacyChangesHeading, l.privacyChanges),
  (l.privacyContactHeading, l.privacyContact(issuesUrl)),
];

const regenerateCommand = '(cd app && flutter test tool/legal_docs.dart)';

/// A legal document as standalone Markdown, for the repository root.
String renderMarkdown(String title, List<LegalSection> sections) {
  final out = StringBuffer()
    ..writeln(
      '<!-- Generated from app/lib/l10n/app_en.arb. '
      'Regenerate with: $regenerateCommand -->',
    )
    ..writeln()
    ..writeln('# $title');
  for (final (heading, body) in sections) {
    final text = [
      for (final run in splitLinks(body)) run.link ? '<${run.text}>' : run.text,
    ].join();
    out
      ..writeln()
      ..writeln('## $heading')
      ..writeln()
      ..writeln(text);
  }
  return out.toString();
}

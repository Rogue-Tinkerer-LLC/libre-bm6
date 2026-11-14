import 'dart:convert';
import 'dart:ui';

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

/// A stable fingerprint of the English Terms, stored on acceptance. Any edit
/// to the Terms changes it; the user's language does not.
String termsFingerprint() {
  final l = lookupAppLocalizations(const Locale('en'));
  return fnv1a64(
    [
      l.termsTitle,
      for (final (heading, body) in termsSections(l)) ...[heading, body],
    ].join('\n'),
  );
}

/// 64-bit FNV-1a over the UTF-8 bytes of [text], as 16 hex digits.
///
/// Written out because [String.hashCode] is not stable across SDK versions.
String fnv1a64(String text) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(text)) {
    hash ^= byte;
    hash *= 0x100000001b3; // Wraps at 64 bits on the Dart VM.
  }
  String half(int value) => value.toRadixString(16).padLeft(8, '0');
  return half(hash >>> 32) + half(hash & 0xffffffff);
}

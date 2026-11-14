// Writes TERMS.md and PRIVACY.md at the repository root from the English
// strings. Runs under `flutter test` because the strings import Flutter:
//   (cd app && flutter test tool/legal_docs.dart)
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/l10n/app_localizations.dart';
import 'package:libre_bm6_app/legal_text.dart';

void main() {
  test('write TERMS.md and PRIVACY.md', () {
    final l = lookupAppLocalizations(const Locale('en'));
    File('../TERMS.md')
        .writeAsStringSync(renderMarkdown(l.termsTitle, termsSections(l)));
    File('../PRIVACY.md')
        .writeAsStringSync(renderMarkdown(l.privacyTitle, privacySections(l)));
  });
}

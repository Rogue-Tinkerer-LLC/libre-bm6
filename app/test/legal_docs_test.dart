import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/l10n/app_localizations.dart';
import 'package:libre_bm6_app/legal_text.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  for (final (file, title, sections) in [
    ('../TERMS.md', l.termsTitle, termsSections(l)),
    ('../PRIVACY.md', l.privacyTitle, privacySections(l)),
  ]) {
    test('$file matches the in-app text', () {
      expect(
        File(file).readAsStringSync(),
        renderMarkdown(title, sections),
        reason: '$file is stale. Regenerate it with: $regenerateCommand',
      );
    });
  }

  test('renderMarkdown writes headings, paragraphs, and autolinks', () {
    expect(
      renderMarkdown('Title', [('Head', 'See https://example.com/x.')]),
      '<!-- Generated from app/lib/l10n/app_en.arb. '
      'Regenerate with: $regenerateCommand -->\n'
      '\n'
      '# Title\n'
      '\n'
      '## Head\n'
      '\n'
      'See <https://example.com/x>.\n',
    );
  });
}

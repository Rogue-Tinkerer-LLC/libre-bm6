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

  group('fnv1a64', () {
    test('matches the published FNV-1a 64-bit vectors', () {
      expect(fnv1a64(''), 'cbf29ce484222325');
      expect(fnv1a64('a'), 'af63dc4c8601ec8c');
      expect(fnv1a64('foobar'), '85944171f73967e8');
    });

    test('is deterministic and changes with one character', () {
      expect(fnv1a64('Terms v1'), fnv1a64('Terms v1'));
      expect(fnv1a64('Terms v1'), isNot(fnv1a64('Terms v2')));
    });
  });

  test('termsFingerprint is stable and 16 hex digits', () {
    expect(termsFingerprint(), termsFingerprint());
    expect(termsFingerprint(), matches(RegExp(r'^[0-9a-f]{16}$')));
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/legal_page.dart';
import 'package:libre_bm6_app/linked_text.dart';

import 'support.dart';

void main() {
  group('splitLinks', () {
    test('leaves a sentence-final period out of the link', () {
      expect(splitLinks('Visit https://example.com/a. Thanks.'), [
        (text: 'Visit ', link: false),
        (text: 'https://example.com/a', link: true),
        (text: '. Thanks.', link: false),
      ]);
    });

    test('handles a URL at either end and plain text alone', () {
      expect(splitLinks('https://a.example b https://c.example'), [
        (text: 'https://a.example', link: true),
        (text: ' b ', link: false),
        (text: 'https://c.example', link: true),
      ]);
      expect(splitLinks('no links'), [(text: 'no links', link: false)]);
    });
  });

  group('legal page links', () {
    testWidgets('tapping the MPL URL opens it', (tester) async {
      final env = FakeEnv();
      await tester.pumpWidget(localized(PrivacyPage(env: env.env)));
      const url = 'https://mozilla.org/MPL/2.0/';
      await tester.scrollUntilVisible(
        find.textContaining(url, findRichText: true),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring(url));

      expect(env.opened, [Uri.parse(url)]);
    });

    testWidgets('tapping the issues URL opens it without the period', (
      tester,
    ) async {
      final env = FakeEnv();
      await tester.pumpWidget(localized(TermsPage(env: env.env)));
      const url = 'https://github.com/Rogue-Tinkerer-LLC/libre-bm6/issues';
      await tester.scrollUntilVisible(
        find.textContaining('$url.', findRichText: true),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring(url));

      expect(env.opened, [Uri.parse(url)]);
    });
  });
}

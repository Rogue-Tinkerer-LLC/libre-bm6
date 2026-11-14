import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/about_page.dart';
import 'package:libre_bm6_app/help_page.dart';

import 'support.dart';

void main() {
  group('AboutPage', () {
    testWidgets('shows the version and build and no support buttons', (
      tester,
    ) async {
      await tester.pumpWidget(localized(AboutPage(env: FakeEnv().env)));
      await tester.pumpAndSettle();

      expect(find.text('Libre BM6'), findsOneWidget);
      expect(find.text('Version 1.2.3 (45)'), findsOneWidget);
      expect(find.textContaining('not affiliated'), findsOneWidget);
      expect(find.text('Contact support'), findsNothing);
      expect(find.text('Report a bug'), findsNothing);
    });

    testWidgets('opens the open-source licenses page', (tester) async {
      await tester.pumpWidget(localized(AboutPage(env: FakeEnv().env)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open-source licenses'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('links to the terms and the privacy policy', (tester) async {
      await tester.pumpWidget(localized(AboutPage(env: FakeEnv().env)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(find.text('No warranty'), findsOneWidget);
    });
  });

  group('HelpPage', () {
    const details = 'App 1.2.3 (45) / Android 17 (API 37)';

    Future<Uri> tapAndCapture(WidgetTester tester, String button) async {
      final env = FakeEnv();
      await tester.pumpWidget(localized(HelpPage(env: env.env)));
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return env.opened.single;
    }

    void expectNewIssue(Uri uri) {
      expect(uri.scheme, 'https');
      expect(uri.host, 'github.com');
      expect(uri.path, '/Rogue-Tinkerer-LLC/libre-bm6/issues/new');
      expect(uri.queryParameters.keys, ['body']);
      expect(uri.toString(), isNot(contains('+')));
      expect(uri.toString(), contains('%20'));
    }

    testWidgets('Contact support opens a new issue with the details', (
      tester,
    ) async {
      final uri = await tapAndCapture(tester, 'Contact support');

      expectNewIssue(uri);
      expect(uri.queryParameters['body'], 'How can we help?\n\n\n$details');
    });

    testWidgets('Report a bug opens a new issue with prompts and details', (
      tester,
    ) async {
      final uri = await tapAndCapture(tester, 'Report a bug');

      expectNewIssue(uri);
      expect(
        uri.queryParameters['body'],
        'What happened:\n\nWhat you expected:\n\nSteps to reproduce:'
        '\n\n\n$details',
      );
    });

    testWidgets('shows the link when nothing can open it', (tester) async {
      final env = FakeEnv()..canOpenLinks = false;
      await tester.pumpWidget(localized(HelpPage(env: env.env)));
      await tester.tap(find.text('Report a bug'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(
          SelectableText,
          'Nothing could open the link. Please visit '
          'https://github.com/Rogue-Tinkerer-LLC/libre-bm6/issues/new.',
        ),
        findsOneWidget,
      );
    });
  });
}

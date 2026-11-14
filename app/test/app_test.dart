import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/app.dart';
import 'package:libre_bm6_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

void main() {
  group('terms gate', () {
    testWidgets('shows the terms on first launch and persists acceptance', (
      tester,
    ) async {
      final store = await pumpApp(tester, prefs: {});
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Saved monitors'), findsNothing);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('Saved monitors'), findsOneWidget);
      expect(Store(await SharedPreferences.getInstance()).termsAccepted, true);
      expect(store.termsAccepted, isTrue);
    });

    testWidgets('skips the terms once accepted', (tester) async {
      await pumpApp(tester);

      expect(find.text('Saved monitors'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
    });

    testWidgets('links to the privacy policy from the first-launch page', (
      tester,
    ) async {
      await pumpApp(tester, prefs: {});
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.textContaining('We treat you and your data'), findsOneWidget);
    });
  });

  group('drawer', () {
    testWidgets('lists About, Help, Terms, and Privacy in order', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      final labels = [
        'About Libre BM6',
        'Help',
        'Terms of Service',
        'Privacy Policy',
      ];
      final tops = [for (final l in labels) tester.getTopLeft(find.text(l)).dy];
      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(4));
    });

    testWidgets('opens the privacy policy', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.textContaining('We treat you and your data'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('github.com'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('github.com'), findsOneWidget);
    });
  });

  group('saved devices', () {
    final saved = {
      'termsAccepted': true,
      'devices': '[{"id":"$deviceId","alias":"Car"}]',
    };

    testWidgets('shows an empty state', (tester) async {
      await pumpApp(tester);

      expect(find.textContaining('No saved monitors yet'), findsOneWidget);
    });

    testWidgets('renames a device and persists it', (tester) async {
      await pumpApp(tester, prefs: saved);
      await tester.tap(find.byTooltip('Actions for Car'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Truck');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Truck'), findsOneWidget);
      final reloaded = Store(await SharedPreferences.getInstance());
      expect(reloaded.devices.single.alias, 'Truck');
    });

    testWidgets('deletes a device only after confirmation', (tester) async {
      await pumpApp(tester, prefs: saved);
      Future<void> chooseDelete() async {
        await tester.tap(find.byTooltip('Actions for Car'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
      }

      await chooseDelete();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Car'), findsOneWidget);

      await chooseDelete();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Car'), findsNothing);
      expect(Store(await SharedPreferences.getInstance()).devices, isEmpty);
    });

    testWidgets('opens the monitor for a tapped device', (tester) async {
      final ble = FakeBle();
      await pumpApp(tester, prefs: saved, ble: ble);
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      expect(find.text('Connecting…'), findsOneWidget);
      expect(ble.liveStreams, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('theme', () {
    test('is black and white in both brightnesses', () {
      final light = buildTheme(Brightness.light).colorScheme;
      final dark = buildTheme(Brightness.dark).colorScheme;

      expect((light.primary, light.surface), (Colors.black, Colors.white));
      expect((dark.primary, dark.surface), (Colors.white, Colors.black));
    });

    testWidgets('follows the system dark mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpApp(tester);

      final context = tester.element(find.text('Saved monitors'));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).colorScheme.surface, Colors.black);
    });

    testWidgets('builds in light mode', (tester) async {
      await pumpApp(tester);

      final context = tester.element(find.text('Saved monitors'));
      expect(Theme.of(context).brightness, Brightness.light);
    });
  });
}

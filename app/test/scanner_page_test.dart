import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/ble.dart';
import 'package:libre_bm6_app/scanner_page.dart';
import 'package:universal_ble/universal_ble.dart';

import 'support.dart';

void main() {
  group('matchesDeviceId', () {
    test('requires the decrypted MAC to equal a MAC-shaped device ID', () {
      expect(matchesDeviceId(deviceId, deviceId), isTrue);
      expect(matchesDeviceId(deviceId.toLowerCase(), deviceId), isTrue);
      expect(matchesDeviceId(deviceId, '11:22:33:44:55:66'), isFalse);
    });

    test('accepts any MAC when the device ID is not a MAC', () {
      expect(matchesDeviceId('opaque-id', deviceId), isTrue);
    });
  });

  test('macSuffix is the last four hex digits', () {
    expect(macSuffix(deviceId), 'E5F6');
  });

  group('ScannerPage', () {
    Future<FakeBle> openScanner(WidgetTester tester, {FakeBle? ble}) async {
      ble ??= FakeBle();
      await pumpApp(tester, ble: ble);
      await tester.tap(find.text('Add'));
      // The progress bar never settles, so pump past the route transition.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      return ble;
    }

    testWidgets('says it is searching before anything is found', (
      tester,
    ) async {
      await openScanner(tester);

      expect(find.textContaining('Looking for monitors'), findsOneWidget);
    });

    testWidgets('lists a device once and updates its voltage', (tester) async {
      final ble = await openScanner(tester);
      ble.scanResults
        ..add((deviceId: deviceId, advertisement: advertisement(voltage: 12.6)))
        ..add((
          deviceId: deviceId,
          advertisement: advertisement(voltage: 12.7),
        ));
      await tester.pump();

      expect(find.text(deviceId), findsOneWidget);
      expect(find.text('12.70 V'), findsOneWidget);
      expect(find.text('12.60 V'), findsNothing);
    });

    testWidgets('hides an advertisement whose MAC does not match', (
      tester,
    ) async {
      final ble = await openScanner(tester);
      ble.scanResults.add((
        deviceId: deviceId,
        advertisement: advertisement(mac: '11:22:33:44:55:66'),
      ));
      await tester.pump();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('saves a device under the chosen alias and returns', (
      tester,
    ) async {
      final ble = await openScanner(tester);
      ble.scanResults.add((deviceId: deviceId, advertisement: advertisement()));
      await tester.pump();
      await tester.tap(find.text(deviceId));
      await tester.pumpAndSettle();

      expect(find.text('Save as'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Monitor E5F6'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Car');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Saved monitors'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
      expect(find.text(deviceId), findsOneWidget);
    });

    testWidgets('shows when Bluetooth is off', (tester) async {
      await openScanner(tester, ble: FakeBle()..readiness = BleReadiness.off);

      expect(find.textContaining('Bluetooth is off'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('shows when permission is denied', (tester) async {
      await openScanner(
        tester,
        ble: FakeBle()..readiness = BleReadiness.denied,
      );

      expect(find.textContaining('needs permission'), findsOneWidget);
    });

    testWidgets('describes a scan error', (tester) async {
      final ble = await openScanner(tester);
      ble.scanResults.addError(
        UniversalBleException(
          code: UniversalBleErrorCode.bluetoothNotEnabled,
          message: 'off',
        ),
      );
      await tester.pump();

      expect(find.textContaining('Bluetooth is off'), findsOneWidget);
    });

    Future<void> pullDown(WidgetTester tester) async {
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('pulling down clears the list and scans again', (tester) async {
      final ble = await openScanner(tester);
      ble.scanResults.add((deviceId: deviceId, advertisement: advertisement()));
      await tester.pump();
      expect(find.text(deviceId), findsOneWidget);

      await pullDown(tester);

      expect(ble.scanListens, 2);
      expect(ble.scanCancels, 1);
      expect(find.text(deviceId), findsNothing);
      expect(find.textContaining('Looking for monitors'), findsOneWidget);
    });

    testWidgets('pulling down works from the empty state', (tester) async {
      final ble = await openScanner(tester);

      await pullDown(tester);

      expect(ble.scanListens, 2);
    });

    testWidgets('pulling down shows a failed readiness check', (tester) async {
      final ble = await openScanner(tester);
      ble.readiness = BleReadiness.off;

      await pullDown(tester);

      expect(ble.scanCancels, 1);
      expect(ble.scanListens, 1);
      expect(find.textContaining('Bluetooth is off'), findsOneWidget);
    });
  });
}

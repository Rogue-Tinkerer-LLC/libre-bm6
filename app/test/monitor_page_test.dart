import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/ble.dart';
import 'package:libre_bm6_app/monitor_page.dart';
import 'package:libre_bm6_app/store.dart';
import 'package:libre_bm6_app/voltage_chart.dart';
import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';

import 'support.dart';

void main() {
  test('celsiusToFahrenheit rounds to whole degrees', () {
    expect(celsiusToFahrenheit(0), 32);
    expect(celsiusToFahrenheit(12), 54);
    expect(celsiusToFahrenheit(-40), -40);
    expect(celsiusToFahrenheit(-5), 23);
  });

  group('MonitorPage', () {
    late FakeBle ble;

    Future<void> openMonitor(WidgetTester tester) async {
      ble = FakeBle();
      await tester.pumpWidget(
        localized(
          MonitorPage(ble: ble.ble, device: const SavedDevice(deviceId, 'Car')),
        ),
      );
      await tester.pump();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }

    Future<void> send(WidgetTester tester, LiveData data) async {
      ble.liveStreams.last.add(data);
      // One pump delivers the event, the next rebuilds.
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the alias and connects', (tester) async {
      await openMonitor(tester);

      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Connecting…'), findsOneWidget);
      expect(ble.liveStreams, hasLength(1));
    });

    testWidgets('shows voltage, temperature, and state of charge', (
      tester,
    ) async {
      await openMonitor(tester);
      await send(tester, frame(voltage: 13.95, temperature: 12));

      expect(find.text('Live'), findsOneWidget);
      expect(find.text('13.95 V'), findsOneWidget);
      expect(find.text('12 °C / 54 °F'), findsOneWidget);
      expect(find.text('80 %'), findsOneWidget);
    });

    testWidgets('shows a negative temperature in both units', (tester) async {
      await openMonitor(tester);
      await send(tester, frame(temperature: -5));

      expect(find.text('-5 °C / 23 °F'), findsOneWidget);
    });

    for (final (status, label) in [
      (0, 'Normal'),
      (1, 'Low'),
      (2, 'Charging'),
      (7, 'Low'),
    ]) {
      testWidgets('shows status $status as $label', (tester) async {
        await openMonitor(tester);
        await send(tester, frame(status: status));

        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('draws the chart once there are two readings', (tester) async {
      await openMonitor(tester);
      await send(tester, frame(voltage: 12.5));
      await send(tester, frame(voltage: 12.7));

      expect(
        find.descendant(
          of: find.byType(VoltageChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('from 12.50 V to 12.70 V')),
        findsOneWidget,
      );
    });

    testWidgets('reports a disconnect and reconnects', (tester) async {
      await openMonitor(tester);
      await send(tester, frame());
      await ble.liveStreams.last.close();
      await tester.pump();

      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(find.text('The monitor disconnected.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(ble.liveStreams, hasLength(2));
    });

    testWidgets('does not connect while Bluetooth is off', (tester) async {
      ble = FakeBle()..readiness = BleReadiness.off;
      await tester.pumpWidget(
        localized(
          MonitorPage(ble: ble.ble, device: const SavedDevice(deviceId, 'Car')),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Bluetooth is off'), findsOneWidget);
      expect(ble.liveStreams, isEmpty);
    });

    testWidgets('pulling down reconnects once and keeps the readings', (
      tester,
    ) async {
      await openMonitor(tester);
      await send(tester, frame(voltage: 13.95));

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(ble.liveStreams, hasLength(2));
      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(find.text('13.95 V'), findsOneWidget);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      await send(tester, frame(voltage: 13.9));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.text('13.90 V'), findsOneWidget);
      expect(ble.liveStreams, hasLength(2));
    });
  });
}

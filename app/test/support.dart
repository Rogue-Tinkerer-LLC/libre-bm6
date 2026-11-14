import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/app.dart';
import 'package:libre_bm6_app/app_env.dart';
import 'package:libre_bm6_app/ble.dart';
import 'package:libre_bm6_app/l10n/app_localizations.dart';
import 'package:libre_bm6_app/legal_text.dart';
import 'package:libre_bm6_app/store.dart';
import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

const deviceId = 'A1:B2:C3:D4:E5:F6';

LiveData frame({
  double voltage = 12.6,
  int temperature = 20,
  int status = 0,
  int stateOfCharge = 80,
}) => LiveData(
  temperature: temperature,
  status: status,
  stateOfCharge: stateOfCharge,
  voltage: voltage,
  rapidAccelerations: 0,
  rapidDecelerations: 0,
);

Advertisement advertisement({String mac = deviceId, double voltage = 12.6}) =>
    Advertisement(
      mac: mac,
      voltage: voltage,
      stateOfCharge: 80,
      status: 0,
      crankingVoltage: 0,
      crankingStatus: 0,
    );

/// Bluetooth with no radio: tests push results through the controllers.
class FakeBle {
  BleReadiness readiness = BleReadiness.ready;
  final scanStreams = <StreamController<ScanResult>>[];
  final liveStreams = <StreamController<LiveData>>[];
  int scanListens = 0;
  int scanCancels = 0;

  /// The most recent scan.
  StreamController<ScanResult> get scanResults => scanStreams.last;

  // The async onCancel callbacks return futures from the test zone, which
  // the widget tester's fake clock can complete.
  Ble get ble => Ble(
    scan: () {
      final controller = StreamController<ScanResult>(
        onListen: () => scanListens++,
        onCancel: () async => scanCancels++,
      );
      scanStreams.add(controller);
      return controller.stream;
    },
    liveData: (id) {
      final controller = StreamController<LiveData>(onCancel: () async {});
      liveStreams.add(controller);
      return controller.stream;
    },
    ready: () async => readiness,
  );
}

class FakeEnv {
  bool canOpenLinks = true;
  final opened = <Uri>[];

  AppEnv get env => AppEnv(
    info: () async =>
        (version: '1.2.3', build: '45', androidRelease: '17', sdkLevel: 37),
    openUri: (uri) async {
      opened.add(uri);
      return canOpenLinks;
    },
  );
}

/// Preferences in which the current Terms are accepted.
Map<String, Object> get accepted => {'acceptedTerms': termsFingerprint()};

Future<Store> loadStore() async => Store(
  await SharedPreferences.getInstance(),
  termsFingerprint: termsFingerprint(),
);

Future<Store> pumpApp(
  WidgetTester tester, {
  Map<String, Object>? prefs,
  FakeBle? ble,
  FakeEnv? env,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? accepted);
  final store = await loadStore();
  await tester.pumpWidget(
    LibreBm6App(
      store: store,
      ble: (ble ?? FakeBle()).ble,
      env: (env ?? FakeEnv()).env,
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Widget localized(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

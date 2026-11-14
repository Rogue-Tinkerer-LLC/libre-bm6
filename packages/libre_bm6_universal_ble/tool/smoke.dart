// Hardware smoke test against a real monitor over BlueZ.
//
// Run from packages/libre_bm6_universal_ble:
//   flutter test tool/smoke.dart
//
// Phase 1 scans for 40 s and picks the first device whose decrypted MAC
// matches its deviceId. Phase 2 streams live data for 30 s while a scan keeps
// running, then cancels and checks the connection with bluetoothctl. Phase 3
// scans again for 15 s.
// A command-line tool, so printing is the output.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';
import 'package:universal_ble/universal_ble.dart';

String _ts() => DateTime.now().toIso8601String().substring(11, 23);

String _hex(List<int> bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(' ');

String _range(List<double> v) => v.isEmpty
    ? 'n/a'
    : '${v.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}'
          '..${v.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)} V';

String _meanInterval(List<DateTime> t) => t.length < 2
    ? 'n/a'
    : '${(t.last.difference(t.first).inMilliseconds / (t.length - 1)).round()} ms';

Future<String?> _scanPhase(String name, Duration duration) async {
  String? match;
  final times = <DateTime>[];
  final volts = <double>[];
  print('--- $name: scan for ${duration.inSeconds} s');
  final sub = scan().listen((event) {
    final a = event.advertisement;
    final matches = event.deviceId.toUpperCase() == a.mac;
    if (matches) {
      match ??= event.deviceId;
      times.add(DateTime.now());
      volts.add(a.voltage);
    }
    print(
      '${_ts()} id=${event.deviceId} mac=${a.mac} match=$matches '
      'V=${a.voltage} soc=${a.stateOfCharge} status=${a.status} '
      'crankV=${a.crankingVoltage} crankStatus=${a.crankingStatus}',
    );
  }, onError: (Object e) => print('${_ts()} scan error: $e'));
  await Future<void>.delayed(duration);
  await sub.cancel();
  print(
    '--- $name summary: matching events=${times.length} '
    'mean interval=${_meanInterval(times)} voltage=${_range(volts)}',
  );
  return match;
}

Future<String> _connected(String deviceId) async {
  final result = await Process.run('bluetoothctl', ['info', deviceId]);
  return '${result.stdout}'
      .split('\n')
      .firstWhere((l) => l.contains('Connected:'), orElse: () => '?')
      .trim();
}

Future<void> _livePhase(String deviceId) async {
  final times = <DateTime>[];
  final volts = <double>[];
  final temps = <int>{};
  var errors = 0;
  var adverts = 0;
  print('--- phase 2: liveData for 30 s, scanning alongside');
  final raw = UniversalBle.characteristicValueStream(deviceId, notifyUuid)
      .listen(
        (v) => print('${_ts()} raw ${v.length} B: ${_hex(decryptBlock(v))}'),
      );
  final scanning = scan().listen((event) {
    if (event.deviceId != deviceId) return;
    adverts++;
    print('${_ts()} advert while connected V=${event.advertisement.voltage}');
  });
  final done = Completer<void>();
  final sub = liveData(deviceId).listen(
    (f) {
      times.add(DateTime.now());
      volts.add(f.voltage);
      temps.add(f.temperature);
      print(
        '${_ts()} frame T=${f.temperature} status=${f.status} '
        'soc=${f.stateOfCharge} V=${f.voltage} '
        'accel=${f.rapidAccelerations} decel=${f.rapidDecelerations}',
      );
    },
    onError: (Object e) {
      errors++;
      print('${_ts()} live error: $e');
    },
    onDone: () {
      print('${_ts()} live stream done');
      if (!done.isCompleted) done.complete();
    },
  );
  await Future.any([
    done.future,
    Future<void>.delayed(const Duration(seconds: 30)),
  ]);
  print('${_ts()} during session: ${await _connected(deviceId)}');
  final watch = Stopwatch()..start();
  await sub.cancel().timeout(
    const Duration(seconds: 15),
    onTimeout: () => print('${_ts()} cancel TIMED OUT'),
  );
  print('${_ts()} cancel took ${watch.elapsedMilliseconds} ms');
  await raw.cancel();
  await scanning.cancel();
  await Future<void>.delayed(const Duration(seconds: 2));
  print('${_ts()} after cancel: ${await _connected(deviceId)}');
  print(
    '--- phase 2 summary: frames=${times.length} '
    'mean interval=${_meanInterval(times)} voltage=${_range(volts)} '
    'temperature=$temps errors=$errors adverts while connected=$adverts',
  );
}

void main() {
  test('smoke', () async {
    // flutter_tester reports Android; force the BlueZ backend.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    var deviceId = await _scanPhase('phase 1', const Duration(seconds: 40));
    deviceId ??= await _scanPhase('phase 1 retry', const Duration(seconds: 20));
    if (deviceId == null) fail('no monitor with a matching MAC found');
    await _livePhase(deviceId);
    await Future<void>.delayed(const Duration(seconds: 3));
    await _scanPhase('phase 3', const Duration(seconds: 15));
    debugDefaultTargetPlatformOverride = null;
  }, timeout: const Timeout(Duration(minutes: 4)));
}

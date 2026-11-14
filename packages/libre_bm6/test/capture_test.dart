import 'dart:convert';
import 'dart:io';

import 'package:libre_bm6/libre_bm6.dart';
import 'package:test/test.dart';

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

void main() {
  final capture = jsonDecode(
    File('test/fixtures/capture-2026-11-14.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final phases = (capture['phases'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic> phase(String name) =>
      phases.firstWhere((p) => p['name'] == name);

  test('the capture device name is supported', () {
    expect(isSupportedName(capture['localName'] as String), isTrue);
  });

  test('notifications decrypt and decode to the recorded frames', () {
    final live = phase('phase2-live');
    final notifications = (live['notifications'] as List)
        .cast<Map<String, dynamic>>();
    final frames = (live['frames'] as List).cast<Map<String, dynamic>>();

    final decoded = <LiveData>[];
    for (final n in notifications) {
      final ciphertext = hex(n['ciphertext'] as String);
      final plaintext = hex(n['plaintext'] as String);
      expect(decryptBlock(ciphertext), plaintext);
      final data = decodeNotification(ciphertext);
      if (plaintext[3] == 0xff) {
        expect(data, isNull);
      } else {
        expect(data, isNotNull);
        decoded.add(data!);
      }
    }

    expect(decoded.length, greaterThanOrEqualTo(frames.length));
    for (var i = 0; i < frames.length; i++) {
      final f = frames[i];
      expect(decoded[i].temperature, f['temperature'], reason: 'frame $i');
      expect(decoded[i].status, f['status'], reason: 'frame $i');
      expect(decoded[i].stateOfCharge, f['stateOfCharge'], reason: 'frame $i');
      expect(decoded[i].voltage, closeTo(f['voltage'] as num, 1e-9));
      expect(decoded[i].rapidAccelerations, f['rapidAccelerations']);
      expect(decoded[i].rapidDecelerations, f['rapidDecelerations']);
    }
  });

  for (final name in ['phase1-passive', 'phase3-passive-after']) {
    test('$name manufacturer data decodes to the recorded voltages', () {
      final results = (phase(name)['rawScanResults'] as List)
          .cast<Map<String, dynamic>>();
      expect(results, isNotEmpty);
      for (final result in results) {
        final entries = (result['manufacturerData'] as List)
            .cast<Map<String, dynamic>>();
        final recorded = result['decodedVoltages'] as List;
        // decodedVoltages lines up one-to-one with manufacturerData.
        expect(recorded.length, entries.length);
        for (var i = 0; i < entries.length; i++) {
          final payload = hex(entries[i]['payload'] as String);
          final ad = decodeManufacturerData(
            entries[i]['companyId'] as int,
            payload,
          );
          if (payload.length != 14) {
            expect(ad, isNull);
            expect(recorded[i], isNull);
            continue;
          }
          expect(ad, isNotNull);
          expect(ad!.mac, capture['deviceId']);
          expect(ad.stateOfCharge, inInclusiveRange(0, 100));
          expect(ad.voltage, closeTo(recorded[i] as num, 1e-9));
        }
      }
    });
  }
}

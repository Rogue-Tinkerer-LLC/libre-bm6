import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';
import 'package:universal_ble/universal_ble.dart';

const deviceId = 'a1:b2:c3:d4:e5:f6';

Uint8List hex(String s) =>
    Uint8List.fromList([for (final b in s.split(' ')) int.parse(b, radix: 16)]);

/// The spec's advertisement vector split the way BLE stacks report it.
ManufacturerData vectorEntry() {
  final ct = hex('c0 6a 9d 97 f3 fd bb 15 9b 64 47 f1 a8 5e a8 5e');
  return ManufacturerData(ct[1] << 8 | ct[0], ct.sublist(2));
}

ManufacturerData encryptedEntry(String plaintext) {
  final ct = encryptBlock(hex(plaintext));
  return ManufacturerData(ct[1] << 8 | ct[0], ct.sublist(2));
}

class FakeBle extends UniversalBlePlatform {
  final calls = <String>[];
  ScanFilter? scanFilter;
  Uint8List? written;
  BleOutputProperty? writeProperty;
  var connected = false;
  var failWrite = false;
  var failStopScan = false;
  Future<void> Function()? onDiscoverServices;

  /// Open subscriptions on the plugin's connection and value streams.
  var listeners = 0;

  void advertise(String? name, List<ManufacturerData> entries) =>
      updateScanResult(
        BleDevice(
          deviceId: deviceId,
          name: name,
          manufacturerDataList: entries,
        ),
      );

  void notify(Uint8List value) =>
      updateCharacteristicValue(deviceId, notifyUuid, value, null);

  void drop() {
    connected = false;
    updateConnection(deviceId, false);
  }

  Stream<T> tracked<T>(Stream<T> source) {
    late StreamSubscription<T> subscription;
    late StreamController<T> controller;
    controller = StreamController(
      sync: true,
      onListen: () {
        listeners++;
        subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      onCancel: () {
        listeners--;
        return subscription.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<BleDevice> get scanStream => tracked(super.scanStream);

  @override
  Stream<bool> connectionStream(String deviceId) =>
      tracked(super.connectionStream(deviceId));

  @override
  Stream<Uint8List> characteristicValueStream(
    String deviceId,
    String characteristicId,
  ) => tracked(super.characteristicValueStream(deviceId, characteristicId));

  @override
  Future<void> startScan({
    ScanFilter? scanFilter,
    PlatformConfig? platformConfig,
  }) async {
    calls.add('startScan');
    this.scanFilter = scanFilter;
  }

  @override
  Future<void> stopScan() async {
    calls.add('stopScan');
    if (failStopScan) throw StateError('bluetooth is off');
  }

  @override
  Future<void> connect(
    String deviceId, {
    Duration? connectionTimeout,
    bool autoConnect = false,
    ConnectionPlatformConfig? platformConfig,
  }) async {
    calls.add('connect');
    connected = true;
    updateConnection(deviceId, true);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    calls.add('disconnect');
    connected = false;
    updateConnection(deviceId, false);
  }

  @override
  Future<BleConnectionState> getConnectionState(String deviceId) async =>
      connected
      ? BleConnectionState.connected
      : BleConnectionState.disconnected;

  @override
  Future<List<BleService>> discoverServices(
    String deviceId,
    bool withDescriptors, {
    DiscoverServicesPlatformConfig? platformConfig,
  }) async {
    calls.add('discoverServices');
    await onDiscoverServices?.call();
    return [];
  }

  @override
  Future<void> setNotifiable(
    String deviceId,
    String service,
    String characteristic,
    BleInputProperty bleInputProperty,
  ) async => calls.add('setNotifiable $characteristic');

  @override
  Future<void> writeValue(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
    BleOutputProperty bleOutputProperty,
  ) async {
    calls.add('writeValue $characteristic');
    if (failWrite) throw StateError('write failed');
    written = value;
    writeProperty = bleOutputProperty;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Lets queued platform calls and stream events run.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeBle ble;

  setUp(() {
    ble = FakeBle();
    UniversalBle.setInstance(ble);
  });

  group('scan', () {
    test('filters on the data service and yields decoded blocks', () async {
      final results = <({String deviceId, Advertisement advertisement})>[];
      final subscription = scan().listen(results.add);
      await settle();
      expect(ble.scanFilter!.withServices, [serviceUuid]);

      ble.advertise('bm6', [vectorEntry()]);
      await settle();

      expect(results, hasLength(1));
      expect(results.single.deviceId, deviceId);
      expect(results.single.advertisement.mac, 'A1:B2:C3:D4:E5:F6');
      expect(results.single.advertisement.voltage, closeTo(13.50, 1e-9));
      await subscription.cancel();
    });

    test('skips other names and entries that are not 14 bytes', () async {
      final results = <Object>[];
      final subscription = scan().listen(results.add);
      await settle();

      ble.advertise('Other', [vectorEntry()]);
      ble.advertise(null, [vectorEntry()]);
      ble.advertise('Battery Guard', [ManufacturerData(0x004c, Uint8List(23))]);
      await settle();

      expect(results, isEmpty);
      await subscription.cancel();
    });

    test('yields only entries new since the previous result', () async {
      final voltages = <double>[];
      final subscription = scan().listen(
        (r) => voltages.add(r.advertisement.voltage),
      );
      await settle();
      final first = vectorEntry();
      final second = encryptedEntry(
        'a1 b2 c3 d4 e5 f6 05 2e 64 00 01 00 00 00 01 08',
      );

      ble.advertise('BM6', [first]);
      ble.advertise('BM6', [first]);
      ble.advertise('BM6', [first, second]);
      await settle();

      expect(voltages, [closeTo(13.50, 1e-9), closeTo(13.26, 1e-9)]);
      await subscription.cancel();
    });

    test('stops scanning on cancel', () async {
      final subscription = scan().listen((_) {});
      await settle();
      ble.advertise('BM6', [vectorEntry()]);
      await settle();
      await subscription.cancel();

      expect(ble.calls, ['startScan', 'stopScan']);
    });

    test('a cancel never throws when the scan cannot be stopped', () async {
      ble.failStopScan = true;
      final subscription = scan().listen((_) {});
      await settle();

      await subscription.cancel();

      expect(ble.listeners, 0);
      ble.failStopScan = false;
      final again = scan().listen((_) {});
      await settle();
      expect(ble.calls, ['startScan', 'stopScan', 'startScan']);
      await again.cancel();
    });
  });

  group('liveData', () {
    test('sends only the encrypted start command with response', () async {
      final subscription = liveData(deviceId).listen((_) {});
      await settle();

      expect(ble.calls, [
        'connect',
        'discoverServices',
        'setNotifiable $notifyUuid',
        'writeValue $commandUuid',
      ]);
      expect(ble.written, startLiveDataCommand);
      expect(ble.writeProperty, BleOutputProperty.withResponse);
      await subscription.cancel();
    });

    test('skips the acknowledgement and yields frames', () async {
      final frames = <LiveData>[];
      final subscription = liveData(deviceId).listen(frames.add);
      await settle();

      ble.notify(
        encryptBlock(hex('d1 55 07 ff 00 00 00 00 00 00 00 00 00 00 00 00')),
      );
      ble.notify(hex('60 5a 04 2a d4 97 01 9a 91 af 63 7f c8 74 c9 d1'));
      await settle();

      expect(frames, hasLength(1));
      expect(frames.single.temperature, 25);
      expect(frames.single.voltage, closeTo(13.75, 1e-9));
      await subscription.cancel();
    });

    test('disconnects on cancel', () async {
      final subscription = liveData(deviceId).listen((_) {});
      await settle();
      await subscription.cancel();

      expect(ble.calls.last, 'disconnect');
    });

    test('a cancel during setup still disconnects', () async {
      await liveData(deviceId).listen((_) {}).cancel();

      expect(ble.calls.last, 'disconnect');
      expect(ble.connected, isFalse);
    });

    test('ends when the device disconnects', () async {
      final done = Completer<void>();
      liveData(deviceId).listen((_) {}, onDone: done.complete);
      await settle();

      ble.connected = false;
      ble.updateConnection(deviceId, false);

      await done.future;
    });

    test('reports a malformed notification and keeps going', () async {
      final errors = <Object>[];
      final frames = <LiveData>[];
      final subscription = liveData(deviceId)
          .listen(frames.add, onError: errors.add);
      await settle();

      ble.notify(Uint8List(20));
      ble.notify(hex('60 5a 04 2a d4 97 01 9a 91 af 63 7f c8 74 c9 d1'));
      await settle();

      expect(errors.single, isArgumentError);
      expect(frames, hasLength(1));
      await subscription.cancel();
    });

    test('ends with the error when setup fails', () async {
      ble.failWrite = true;
      final errors = <Object>[];
      final done = Completer<void>();
      liveData(deviceId)
          .listen((_) {}, onError: errors.add, onDone: done.complete);

      await done.future;
      expect(errors.single, isA<StateError>());
      expect(ble.calls.last, 'disconnect');
    });

    test('a disconnect during setup then a failure ends cleanly', () async {
      ble.onDiscoverServices = () async {
        ble.drop();
        await settle();
        throw StateError('discovery failed');
      };
      final errors = <Object>[];
      final done = Completer<void>();
      liveData(deviceId)
          .listen((_) {}, onError: errors.add, onDone: done.complete);

      await done.future;
      await settle();
      expect(errors, isEmpty);
      expect(ble.listeners, 0);
      expect(ble.calls, ['connect', 'discoverServices', 'disconnect']);
    });

    test('a repeated disconnect event is harmless', () async {
      final done = Completer<void>();
      liveData(deviceId).listen((_) {}, onDone: done.complete);
      await settle();

      ble
        ..drop()
        ..drop();
      await done.future;
      await settle();

      expect(ble.listeners, 0);
      expect(ble.calls.last, 'disconnect');
    });

    test('a malformed notification after a disconnect is dropped', () async {
      final errors = <Object>[];
      final done = Completer<void>();
      liveData(deviceId)
          .listen((_) {}, onError: errors.add, onDone: done.complete);
      await settle();

      ble
        ..drop()
        ..notify(Uint8List(20));
      await done.future;
      await settle();

      expect(errors, isEmpty);
      expect(ble.listeners, 0);
    });

    test('notifications during cancel are dropped', () async {
      final events = <Object>[];
      final subscription = liveData(deviceId)
          .listen(events.add, onError: events.add);
      await settle();

      final cancelled = subscription.cancel();
      ble
        ..notify(hex('60 5a 04 2a d4 97 01 9a 91 af 63 7f c8 74 c9 d1'))
        ..notify(Uint8List(20));
      await cancelled;
      await settle();

      expect(events, isEmpty);
      expect(ble.listeners, 0);
      expect(ble.calls.last, 'disconnect');
    });

    test('replays the hardware capture', () async {
      final capture = jsonDecode(
        File('../libre_bm6/test/fixtures/capture-2026-11-14.json')
            .readAsStringSync(),
      ) as Map<String, Object?>;
      final phase = (capture['phases'] as List<Object?>)
          .cast<Map<String, Object?>>()
          .singleWhere((p) => p['name'] == 'phase2-live');
      final notifications = (phase['notifications'] as List<Object?>)
          .cast<Map<String, Object?>>();
      final captured = (phase['frames'] as List<Object?>)
          .cast<Map<String, Object?>>();
      Map<String, Object?> fields(LiveData d) => {
        'temperature': d.temperature,
        'status': d.status,
        'stateOfCharge': d.stateOfCharge,
        'voltage': d.voltage,
        'rapidAccelerations': d.rapidAccelerations,
        'rapidDecelerations': d.rapidDecelerations,
      };
      Map<String, Object?> matches(Map<String, Object?> f) =>
          {...f, 'voltage': closeTo(f['voltage']! as double, 1e-9)}
            ..remove('t');

      final frames = <LiveData>[];
      final subscription = liveData(deviceId).listen(frames.add);
      await settle();
      for (final n in notifications) {
        ble.notify(hex(n['ciphertext'] as String));
      }
      await settle();
      await subscription.cancel();

      final decoded = [
        for (final n in notifications)
          LiveData.parse(hex(n['plaintext'] as String)),
      ];
      expect(decoded.first, isNull, reason: 'the acknowledgement');
      expect(decoded.skip(1), everyElement(isNotNull));
      expect(frames.map(fields), [
        for (final d in decoded.skip(1)) matches(fields(d!)),
      ]);
      expect(frames.take(captured.length).map(fields), captured.map(matches));
    });
  });
}

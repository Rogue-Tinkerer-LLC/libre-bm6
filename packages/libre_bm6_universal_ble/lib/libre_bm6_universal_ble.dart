/// Reads the BM6 battery monitor through `universal_ble`.
library;

import 'dart:async';

import 'package:libre_bm6/libre_bm6.dart';
import 'package:universal_ble/universal_ble.dart';

export 'package:libre_bm6/libre_bm6.dart';

/// Scans for monitors and yields their decrypted advertisements (passive
/// mode).
///
/// Scanning starts on listen and stops when the subscription is cancelled.
/// Compare [Advertisement.mac] to `deviceId` where the platform reports a MAC.
Stream<({String deviceId, Advertisement advertisement})> scan() {
  // BlueZ reports every block it has cached under its fake company id, so
  // only entries that were not in the device's previous result are current.
  final previous = <String, List<ManufacturerData>>{};
  late final StreamSubscription<BleDevice> results;
  late final StreamController<({String deviceId, Advertisement advertisement})>
  controller;
  void onResult(BleDevice device) {
    if (!isSupportedName(device.name)) return;
    final seen = previous[device.deviceId] ?? const [];
    previous[device.deviceId] = device.manufacturerDataList;
    for (final entry in device.manufacturerDataList) {
      if (seen.contains(entry)) continue;
      final advertisement = decodeManufacturerData(
        entry.companyId,
        entry.payload,
      );
      if (advertisement != null) {
        controller.add((
          deviceId: device.deviceId,
          advertisement: advertisement,
        ));
      }
    }
  }

  controller = StreamController(
    onListen: () {
      results = UniversalBle.scanStream.listen(
        onResult,
        onError: controller.addError,
      );
      UniversalBle.startScan(
        scanFilter: ScanFilter(withServices: [serviceUuid]),
      ).catchError(controller.addError);
    },
    onCancel: () async {
      await results.cancel();
      await UniversalBle.stopScan();
    },
  );
  return controller.stream;
}

/// Connects to [deviceId], sends the start-live-data command, and yields
/// live-data frames (active mode), about one per second.
///
/// Cancelling the subscription disconnects. The stream ends if the device
/// disconnects or setup fails. A notification that is not 16 bytes arrives
/// as an [ArgumentError] event and does not end the stream.
Stream<LiveData> liveData(String deviceId) {
  final subscriptions = <StreamSubscription<Object?>>[];
  late final StreamController<LiveData> controller;
  late final Future<void> started;
  Future<void> start() async {
    await UniversalBle.connect(deviceId);
    // Listen before writing so the first frames cannot be missed.
    subscriptions.addAll([
      UniversalBle.characteristicValueStream(
        deviceId,
        notifyUuid,
      ).map(decodeNotification).listen((data) {
        if (data != null && !controller.isClosed) controller.add(data);
      }, onError: controller.addError),
      UniversalBle.connectionStream(deviceId).listen((connected) {
        if (!connected) controller.close();
      }),
    ]);
    await UniversalBle.discoverServices(deviceId);
    await UniversalBle.subscribeNotifications(
      deviceId,
      serviceUuid,
      notifyUuid,
    );
    await UniversalBle.write(
      deviceId,
      serviceUuid,
      commandUuid,
      startLiveDataCommand,
      withoutResponse: true,
    );
  }

  controller = StreamController(
    onListen: () => started = start().catchError((Object e, StackTrace s) {
      controller
        ..addError(e, s)
        ..close();
    }),
    onCancel: () async {
      // A cancel during setup must not leave the device connected.
      await started;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await UniversalBle.disconnect(deviceId);
    },
  );
  return controller.stream;
}

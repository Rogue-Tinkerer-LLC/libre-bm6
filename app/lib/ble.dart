import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart'
    as adapter;
import 'package:universal_ble/universal_ble.dart';

import 'l10n/app_localizations.dart';
import 'live_session.dart';

enum BleReadiness { ready, off, denied }

typedef ScanResult = ({String deviceId, adapter.Advertisement advertisement});

/// The Bluetooth functions the pages use, so tests can swap in fakes.
class Ble {
  const Ble({required this.scan, required this.liveData, required this.ready});

  static const platform = Ble(
    scan: adapter.scan,
    liveData: adapter.liveData,
    ready: _platformReady,
  );

  final Stream<ScanResult> Function() scan;
  final Stream<adapter.LiveData> Function(String deviceId) liveData;

  /// Requests the Bluetooth permissions if needed and reports whether
  /// Bluetooth can be used.
  final Future<BleReadiness> Function() ready;
}

Future<BleReadiness> _platformReady() async {
  if (!await UniversalBle.hasPermissions()) {
    try {
      await UniversalBle.requestPermissions();
    } on Exception {
      // The plugin throws when the user denies the request.
      return BleReadiness.denied;
    }
  }
  return switch (await UniversalBle.getBluetoothAvailabilityState()) {
    AvailabilityState.poweredOn => BleReadiness.ready,
    AvailabilityState.unauthorized => BleReadiness.denied,
    _ => BleReadiness.off,
  };
}

String describeError(AppLocalizations l, Object error) => switch (error) {
  LinkProblem.disconnected => l.errorDisconnected,
  LinkProblem.stalled => l.errorStalled,
  LinkProblem.notFound => l.errorNotFound,
  UniversalBleException(:final code) => switch (code) {
    UniversalBleErrorCode.bluetoothNotEnabled ||
    UniversalBleErrorCode.bluetoothNotAvailable => l.bluetoothOff,
    UniversalBleErrorCode.bluetoothUnauthorized ||
    UniversalBleErrorCode.bluetoothNotAllowed => l.permissionDenied,
    UniversalBleErrorCode.deviceNotFound ||
    UniversalBleErrorCode.connectionTimeout => l.errorNotFound,
    _ => l.errorConnection,
  },
  ArgumentError() => l.errorBadReading,
  _ => l.errorUnknown,
};

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libre_bm6_universal_ble/libre_bm6_universal_ble.dart';

import 'ble.dart';
import 'devices_page.dart';
import 'l10n/app_localizations.dart';
import 'store.dart';

final _macPattern = RegExp(
  r'^[0-9A-F]{2}(:[0-9A-F]{2}){5}$',
  caseSensitive: false,
);

/// Whether an advertisement plausibly came from [deviceId].
///
/// The protocol has no checksum, so a foreign block decodes as garbage. Where
/// the platform reports a MAC (Android), the decrypted MAC must match it.
bool matchesDeviceId(String deviceId, String mac) =>
    !_macPattern.hasMatch(deviceId) || deviceId.toUpperCase() == mac;

/// The last four hex digits of [mac], for a default alias.
String macSuffix(String mac) {
  final digits = mac.replaceAll(':', '');
  return digits.substring(digits.length - 4);
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.ble, required this.store});

  final Ble ble;
  final Store store;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  BleReadiness? _readiness;
  Object? _error;
  final _found = <String, Advertisement>{};
  StreamSubscription<ScanResult>? _subscription;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) return;
    setState(() {
      _readiness = null;
      _error = null;
      _found.clear();
    });
    final readiness = await widget.ble.ready();
    if (!mounted) return;
    setState(() => _readiness = readiness);
    if (readiness != BleReadiness.ready) return;
    _subscription = widget.ble.scan().listen((result) {
      final (:deviceId, :advertisement) = result;
      if (!matchesDeviceId(deviceId, advertisement.mac)) return;
      setState(() => _found[deviceId] = advertisement);
    }, onError: (Object error) => setState(() => _error = error));
  }

  Future<void> _saveAs(String deviceId, Advertisement advertisement) async {
    final l = AppLocalizations.of(context);
    final alias = await showAliasDialog(
      context,
      title: l.saveAsTitle,
      initial: l.defaultAlias(macSuffix(advertisement.mac)),
    );
    if (alias == null) return;
    await widget.store.save(deviceId, alias);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final error = _error;
    final message = switch (_readiness) {
      null => l.scannerChecking,
      BleReadiness.off => l.bluetoothOff,
      BleReadiness.denied => l.permissionDenied,
      BleReadiness.ready when error != null => describeError(l, error),
      BleReadiness.ready when _found.isEmpty => l.scannerSearching,
      BleReadiness.ready => l.scannerHint,
    };
    final failed =
        _readiness == BleReadiness.off ||
        _readiness == BleReadiness.denied ||
        error != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.scannerTitle)),
      body: RefreshIndicator(
        onRefresh: _start,
        semanticsLabel: l.refreshLabel,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(message)),
            if (failed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    onPressed: _start,
                    child: Text(l.retry),
                  ),
                ),
              ),
            if (_readiness == BleReadiness.ready && _found.isEmpty && !failed)
              const LinearProgressIndicator(),
            for (final MapEntry(key: id, value: advertisement)
                in _found.entries)
              ListTile(
                title: Text(advertisement.mac),
                trailing: Text(l.voltageValue(advertisement.voltage)),
                onTap: () => _saveAs(id, advertisement),
              ),
          ],
        ),
      ),
    );
  }
}

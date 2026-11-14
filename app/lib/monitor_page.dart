import 'dart:async';

import 'package:flutter/material.dart';

import 'ble.dart';
import 'l10n/app_localizations.dart';
import 'live_session.dart';
import 'store.dart';
import 'voltage_chart.dart';

/// Whole degrees Fahrenheit for whole degrees Celsius, rounded.
int celsiusToFahrenheit(int celsius) => (celsius * 9 / 5 + 32).round();

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key, required this.ble, required this.device});

  final Ble ble;
  final SavedDevice device;

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  late final _session = LiveSession(
    widget.ble.liveData,
    widget.device.id,
    onChange: () {
      if (mounted) setState(() {});
    },
  );
  BleReadiness? _readiness;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    unawaited(_session.close());
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _readiness = null);
    final readiness = await widget.ble.ready();
    if (!mounted) return;
    setState(() => _readiness = readiness);
    // A pull during the first check runs a second check alongside it.
    if (readiness != BleReadiness.ready || _started) return;
    _started = true;
    _session.start();
  }

  Future<void> _refresh() async {
    if (!_started) return _start();
    await _session.restart();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final data = _session.latest;
    final error = _session.lastError;
    final readiness = _readiness;
    final link = switch (_session.state) {
      LinkState.connecting => l.linkConnecting,
      LinkState.live => l.linkLive,
      LinkState.reconnecting => l.linkReconnecting,
    };
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.alias)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        semanticsLabel: l.refreshLabel,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (readiness == BleReadiness.off ||
                readiness == BleReadiness.denied) ...[
              Text(
                readiness == BleReadiness.off
                    ? l.bluetoothOff
                    : l.permissionDenied,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(onPressed: _start, child: Text(l.retry)),
              ),
            ] else ...[
              Semantics(
                liveRegion: true,
                child: Text(link, style: text.titleMedium),
              ),
              if (error != null) Text(describeError(l, error)),
            ],
            const SizedBox(height: 24),
            Text(l.voltageLabel, style: text.labelLarge),
            Text(
              data == null ? l.noValue : l.voltageValue(data.voltage),
              style: text.displayLarge,
            ),
            const SizedBox(height: 16),
            VoltageChart(voltages: List.of(_session.history)),
            const SizedBox(height: 16),
            _Reading(
              label: l.temperatureLabel,
              value: data == null
                  ? l.noValue
                  : l.temperatureValue(
                      data.temperature,
                      celsiusToFahrenheit(data.temperature),
                    ),
            ),
            _Reading(
              label: l.stateOfChargeLabel,
              value: data == null
                  ? l.noValue
                  : l.stateOfChargeValue(data.stateOfCharge),
            ),
            _Reading(
              label: l.statusLabel,
              value: switch (data?.status) {
                null => l.noValue,
                0 => l.statusNormal,
                2 => l.statusCharging,
                // 1 is low; anything undocumented is treated as low too.
                _ => l.statusLow,
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

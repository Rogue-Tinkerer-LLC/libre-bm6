import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedDevice {
  const SavedDevice(this.id, this.alias);

  final String id;
  final String alias;
}

/// Terms acceptance and saved devices, persisted in app-local preferences.
///
/// Acceptance is stored as the fingerprint of the Terms that were accepted,
/// so any change to the Terms asks again.
class Store extends ChangeNotifier {
  Store(this._prefs, {required this.termsFingerprint})
    : _devices = _decode(_prefs.getString(_devicesKey));

  static const _termsKey = 'acceptedTerms';
  static const _devicesKey = 'devices';

  final SharedPreferences _prefs;
  final String termsFingerprint;
  final List<SavedDevice> _devices;

  bool get termsAccepted => _prefs.getString(_termsKey) == termsFingerprint;

  List<SavedDevice> get devices => List.unmodifiable(_devices);

  Future<void> acceptTerms() async {
    await _prefs.setString(_termsKey, termsFingerprint);
    notifyListeners();
  }

  /// Adds a device, or renames it if [id] is already saved.
  Future<void> save(String id, String alias) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index < 0) {
      _devices.add(SavedDevice(id, alias));
    } else {
      _devices[index] = SavedDevice(id, alias);
    }
    await _persist();
  }

  Future<void> remove(String id) async {
    _devices.removeWhere((d) => d.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _prefs.setString(
      _devicesKey,
      jsonEncode([
        for (final d in _devices) {'id': d.id, 'alias': d.alias},
      ]),
    );
  }

  static List<SavedDevice> _decode(String? json) => [
    if (json != null)
      for (final d in jsonDecode(json) as List<dynamic>)
        SavedDevice(d['id'] as String, d['alias'] as String),
  ];
}

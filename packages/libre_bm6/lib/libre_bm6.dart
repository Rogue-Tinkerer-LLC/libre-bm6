/// Protocol codec for the BM6 BLE battery monitor.
library;

import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';

/// Data service UUID. Also the scan filter.
const serviceUuid = '0000fff0-0000-1000-8000-00805f9b34fb';

/// Command characteristic. Written without response.
const commandUuid = '0000fff3-0000-1000-8000-00805f9b34fb';

/// Notification characteristic carrying replies and live data.
const notifyUuid = '0000fff4-0000-1000-8000-00805f9b34fb';

/// Device names the monitor advertises, lower-case.
const deviceNames = {'bm6', 'battery guard'};

/// Whether [name] is one of [deviceNames], ignoring case.
bool isSupportedName(String? name) =>
    name != null && deviceNames.contains(name.toLowerCase());

/// The fixed AES-128 transport key shared by every device.
final key = Uint8List.fromList([
  0x6c, 0x65, 0x61, 0x67, 0x65, 0x6e, 0x64, 0xff, //
  0xfe, 0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x39,
]);

/// Encrypts one 16-byte block with [key].
///
/// AES-ECB on a single block equals the device's CBC with a zero IV.
Uint8List encryptBlock(List<int> plaintext) => _aes(true, plaintext);

/// Decrypts one 16-byte block with [key].
Uint8List decryptBlock(List<int> ciphertext) => _aes(false, ciphertext);

Uint8List _aes(bool forEncryption, List<int> block) {
  if (block.length != 16) {
    throw ArgumentError.value(block.length, 'block.length', 'must be 16');
  }
  final out = Uint8List(16);
  (AESEngine()..init(forEncryption, KeyParameter(key))).processBlock(
    Uint8List.fromList(block),
    0,
    out,
    0,
  );
  return out;
}

/// The encrypted "start live data" command `D1 55 07`, ready for
/// [commandUuid].
final startLiveDataCommand = encryptBlock([
  0xd1, 0x55, 0x07, 0, 0, 0, 0, 0, //
  0, 0, 0, 0, 0, 0, 0, 0,
]);

int _uint16(List<int> b, int offset) => b[offset] << 8 | b[offset + 1];

/// A decrypted advertisement block (passive mode).
class Advertisement {
  /// Device MAC, upper-case and colon-separated (`A1:B2:C3:D4:E5:F6`).
  final String mac;

  /// Present battery voltage in volts.
  final double voltage;

  /// State of charge in percent.
  final int stateOfCharge;

  /// Battery status: 0 normal, 1 low, 2 charging.
  final int status;

  /// Last stored cranking (engine-start) voltage in volts.
  final double crankingVoltage;

  /// Cranking-test status. 2 means a low cranking voltage.
  final int crankingStatus;

  const Advertisement({
    required this.mac,
    required this.voltage,
    required this.stateOfCharge,
    required this.status,
    required this.crankingVoltage,
    required this.crankingStatus,
  });

  /// Parses a decrypted 16-byte advertisement block.
  factory Advertisement.parse(List<int> plaintext) {
    if (plaintext.length != 16) {
      throw ArgumentError.value(plaintext.length, 'length', 'must be 16');
    }
    return Advertisement(
      mac: plaintext
          .sublist(0, 6)
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':'),
      voltage: _uint16(plaintext, 6) / 100,
      stateOfCharge: plaintext[8],
      status: plaintext[9],
      crankingVoltage: _uint16(plaintext, 11) / 100,
      crankingStatus: plaintext[13],
    );
  }
}

/// Decrypts a manufacturer data entry as reported by stacks that split off
/// the company identifier.
///
/// Returns null when [data] is not 14 bytes, such as an iBeacon entry.
Advertisement? decodeManufacturerData(int companyId, List<int> data) {
  if (data.length != 14) return null;
  // The "company identifier" is really the first two ciphertext bytes,
  // sent low byte first.
  return Advertisement.parse(
    decryptBlock([companyId & 0xff, companyId >> 8, ...data]),
  );
}

/// Decrypts the first AD structure with length `0x11` and type `0xFF` in a
/// raw advertisement record, or returns null if there is none.
Advertisement? decodeScanRecord(List<int> record) {
  for (var i = 0; i + 1 < record.length && record[i] != 0;) {
    final length = record[i];
    if (length == 0x11 && record[i + 1] == 0xff && i + 18 <= record.length) {
      return Advertisement.parse(decryptBlock(record.sublist(i + 2, i + 18)));
    }
    i += length + 1;
  }
  return null;
}

/// A decrypted live-data frame (active mode).
class LiveData {
  /// Temperature in whole degrees Celsius.
  final int temperature;

  /// Battery status: 0 normal, 1 low, 2 charging.
  final int status;

  /// State of charge in percent.
  final int stateOfCharge;

  /// Battery voltage in volts.
  final double voltage;

  /// Rapid-acceleration event count.
  final int rapidAccelerations;

  /// Rapid-deceleration event count.
  final int rapidDecelerations;

  const LiveData({
    required this.temperature,
    required this.status,
    required this.stateOfCharge,
    required this.voltage,
    required this.rapidAccelerations,
    required this.rapidDecelerations,
  });

  /// Parses a decrypted 16-byte frame.
  ///
  /// Returns null for the `D1 55 07 FF` acknowledgement and for any frame
  /// that is not live data.
  static LiveData? parse(List<int> plaintext) {
    if (plaintext.length != 16) {
      throw ArgumentError.value(plaintext.length, 'length', 'must be 16');
    }
    if (plaintext[0] != 0xd1 || plaintext[1] != 0x55 || plaintext[2] != 0x07) {
      return null;
    }
    // Byte 3 doubles as the temperature sign, so the ack check comes first.
    if (plaintext[3] == 0xff) return null;
    return LiveData(
      temperature: plaintext[3] == 0x01 ? -plaintext[4] : plaintext[4],
      status: plaintext[5],
      stateOfCharge: plaintext[6],
      voltage: _uint16(plaintext, 7) / 100,
      rapidAccelerations: _uint16(plaintext, 9),
      rapidDecelerations: _uint16(plaintext, 11),
    );
  }
}

/// Decrypts and parses a 16-byte notification from [notifyUuid].
///
/// Returns null for the acknowledgement and for non-live-data frames.
/// Throws [ArgumentError] if [value] is not 16 bytes.
LiveData? decodeNotification(List<int> value) =>
    LiveData.parse(decryptBlock(value));

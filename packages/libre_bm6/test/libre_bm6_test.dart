import 'package:libre_bm6/libre_bm6.dart';
import 'package:test/test.dart';

List<int> hex(String s) => [
  for (final b in s.split(' ')) int.parse(b, radix: 16),
];

List<int> padded(List<int> command) => [
  ...command,
  ...List.filled(16 - command.length, 0),
];

void main() {
  group('encryptBlock', () {
    final vectors = {
      'start live data': (
        0x07,
        '69 7e a0 b5 d5 4c f0 24 e7 94 77 23 55 55 41 14',
      ),
      'read version': (0x01, '1a d6 f0 5e 49 90 ab 24 b8 4d 57 df 81 d8 76 6e'),
      'authorize': (0x02, '9c b1 80 29 77 4c 5c fc 57 c9 f1 14 d4 0d b4 e8'),
      'read crank test': (
        0x03,
        'd3 90 bf 65 d7 d8 57 43 6e 94 71 04 2f 85 45 6f',
      ),
    };
    for (final MapEntry(key: name, value: (type, ciphertext))
        in vectors.entries) {
      test('matches the spec ciphertext for $name', () {
        expect(encryptBlock(padded([0xd1, 0x55, type])), hex(ciphertext));
      });
    }

    test('decryptBlock inverts it', () {
      final plaintext = padded([0xd1, 0x55, 0x07]);
      expect(decryptBlock(encryptBlock(plaintext)), plaintext);
    });

    test('rejects a block that is not 16 bytes', () {
      expect(() => encryptBlock(List.filled(15, 0)), throwsArgumentError);
      expect(() => decryptBlock(List.filled(17, 0)), throwsArgumentError);
    });
  });

  test('startLiveDataCommand is the encrypted D1 55 07', () {
    expect(
      startLiveDataCommand,
      hex('69 7e a0 b5 d5 4c f0 24 e7 94 77 23 55 55 41 14'),
    );
  });

  group('isSupportedName', () {
    test('accepts both names in any case', () {
      expect(isSupportedName('BM6'), isTrue);
      expect(isSupportedName('bm6'), isTrue);
      expect(isSupportedName('Battery Guard'), isTrue);
      expect(isSupportedName('BATTERY GUARD'), isTrue);
    });

    test('rejects other names and null', () {
      expect(isSupportedName('BM6 '), isFalse);
      expect(isSupportedName('BM'), isFalse);
      expect(isSupportedName(null), isFalse);
    });
  });

  group('decodeNotification', () {
    test('decodes the round-trip vector', () {
      final data = decodeNotification(
        hex('60 5a 04 2a d4 97 01 9a 91 af 63 7f c8 74 c9 d1'),
      )!;
      expect(data.temperature, 25);
      expect(data.status, 0);
      expect(data.stateOfCharge, 0);
      expect(data.voltage, closeTo(13.75, 1e-9));
      expect(data.rapidAccelerations, 3);
      expect(data.rapidDecelerations, 1);
    });

    test('round-trip plaintext encrypts to the spec ciphertext', () {
      expect(
        encryptBlock(hex('d1 55 07 00 19 00 00 05 5f 00 03 00 01 00 00 00')),
        hex('60 5a 04 2a d4 97 01 9a 91 af 63 7f c8 74 c9 d1'),
      );
    });

    test('decodes the real-device frame', () {
      final data = decodeNotification(
        encryptBlock(hex('d1 55 07 00 0E 02 64 05 CD 00 00 00 00 02 00 00')),
      )!;
      expect(data.temperature, 14);
      expect(data.status, 2);
      expect(data.stateOfCharge, 100);
      expect(data.voltage, closeTo(14.85, 1e-9));
      expect(data.rapidAccelerations, 0);
      expect(data.rapidDecelerations, 0);
    });

    test('rejects a value that is not 16 bytes', () {
      expect(() => decodeNotification(List.filled(32, 0)), throwsArgumentError);
    });
  });

  group('LiveData.parse', () {
    test('applies a negative sign when byte 3 is 0x01', () {
      final data = LiveData.parse(
        hex('d1 55 07 01 05 01 32 04 b0 00 00 00 00 00 00 00'),
      )!;
      expect(data.temperature, -5);
      expect(data.status, 1);
      expect(data.voltage, closeTo(12.0, 1e-9));
    });

    test('ignores the D1 55 07 FF acknowledgement', () {
      expect(
        LiveData.parse(hex('d1 55 07 ff 00 00 00 00 00 00 00 00 00 00 00 00')),
        isNull,
      );
    });

    test('ignores frames of another type', () {
      expect(LiveData.parse(padded([0xd1, 0x55, 0x01, 0x01, 0x07])), isNull);
      expect(LiveData.parse(padded([0x00, 0x55, 0x07])), isNull);
    });

    test('rejects input that is not 16 bytes', () {
      expect(() => LiveData.parse([0xd1, 0x55, 0x07]), throwsArgumentError);
    });
  });

  group('Advertisement', () {
    const vectorPlaintext = 'a1 b2 c3 d4 e5 f6 05 46 50 00 00 00 00 00 00 00';
    const vectorCiphertext = 'c0 6a 9d 97 f3 fd bb 15 9b 64 47 f1 a8 5e a8 5e';

    void expectVector(Advertisement? ad) {
      expect(ad, isNotNull);
      expect(ad!.mac, 'A1:B2:C3:D4:E5:F6');
      expect(ad.voltage, closeTo(13.50, 1e-9));
      expect(ad.stateOfCharge, 80);
      expect(ad.status, 0);
    }

    test('vector plaintext encrypts to the spec ciphertext', () {
      expect(encryptBlock(hex(vectorPlaintext)), hex(vectorCiphertext));
    });

    test('parses the example decrypted block', () {
      final ad = Advertisement.parse(
        hex('A1 B2 C3 D4 E5 F6 05 2E 64 00 01 00 00 00 01 08'),
      );
      expect(ad.mac, 'A1:B2:C3:D4:E5:F6');
      expect(ad.voltage, closeTo(13.26, 1e-9));
      expect(ad.stateOfCharge, 100);
      expect(ad.status, 0);
      expect(ad.crankingVoltage, 0);
      expect(ad.crankingStatus, 0);
    });

    test('parses cranking voltage and status', () {
      final ad = Advertisement.parse(
        hex('00 00 00 00 00 01 04 b0 0a 01 00 02 58 02 00 00'),
      );
      expect(ad.mac, '00:00:00:00:00:01');
      expect(ad.crankingVoltage, closeTo(6.0, 1e-9));
      expect(ad.crankingStatus, 2);
    });

    test('rejects input that is not 16 bytes', () {
      expect(
        () => Advertisement.parse(List.filled(14, 0)),
        throwsArgumentError,
      );
    });

    test('decodeManufacturerData rebuilds the company id little-endian', () {
      final ct = hex(vectorCiphertext);
      expectVector(decodeManufacturerData(ct[1] << 8 | ct[0], ct.sublist(2)));
    });

    test('decodeManufacturerData skips an entry that is not 14 bytes', () {
      expect(decodeManufacturerData(0x004c, List.filled(23, 0)), isNull);
      expect(decodeManufacturerData(0x6ac0, List.filled(13, 0)), isNull);
    });

    test('decodeScanRecord takes the first 0x11 0xFF structure', () {
      final record = [
        0x02, 0x01, 0x06, // flags
        0x1a, 0xff, 0x4c, 0x00, 0x02, 0x15, ...List.filled(21, 0), // iBeacon
        0x04, 0x09, 0x42, 0x4d, 0x36, // name "BM6"
        0x11, 0xff, ...hex(vectorCiphertext),
      ];
      expectVector(decodeScanRecord(record));
    });

    test('decodeScanRecord returns null without the structure', () {
      expect(decodeScanRecord([0x02, 0x01, 0x06, 0x00, 0x00]), isNull);
      expect(decodeScanRecord([0x11, 0xff, 0x00]), isNull);
    });
  });
}

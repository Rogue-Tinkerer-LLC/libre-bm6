import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const deviceId = 'A1:B2:C3:D4:E5:F6';

Future<Store> reload() async =>
    Store(await SharedPreferences.getInstance(), termsFingerprint: 'abc');

void main() {
  group('Store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts with the terms not accepted and no devices', () async {
      final store = await reload();

      expect(store.termsAccepted, isFalse);
      expect(store.devices, isEmpty);
    });

    test('persists terms acceptance as the fingerprint', () async {
      await (await reload()).acceptTerms();

      expect((await reload()).termsAccepted, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('acceptedTerms'), 'abc');
    });

    test('asks again when the Terms fingerprint changes', () async {
      await (await reload()).acceptTerms();
      final prefs = await SharedPreferences.getInstance();

      expect(Store(prefs, termsFingerprint: 'abd').termsAccepted, isFalse);
    });

    test('persists added, renamed, and removed devices', () async {
      final store = await reload();
      await store.save(deviceId, 'Car');
      await store.save('11:22:33:44:55:66', 'Boat');
      await store.save(deviceId, 'Truck');

      final reloaded = await reload();
      expect(
        [for (final d in reloaded.devices) (d.id, d.alias)],
        [(deviceId, 'Truck'), ('11:22:33:44:55:66', 'Boat')],
      );

      await reloaded.remove(deviceId);
      expect(
        [for (final d in (await reload()).devices) d.id],
        ['11:22:33:44:55:66'],
      );
    });

    group('unreadable saved data', () {
      Future<Store> reloadWith(Map<String, Object> values) async {
        SharedPreferences.setMockInitialValues(values);
        return reload();
      }

      test('treats invalid JSON as no devices', () async {
        expect((await reloadWith({'devices': 'not json'})).devices, isEmpty);
      });

      test('treats an entry missing its alias as no devices', () async {
        final store = await reloadWith({'devices': '[{"id":"x"}]'});

        expect(store.devices, isEmpty);
      });

      test(
        'treats a non-string accepted-terms value as not accepted',
        () async {
          expect(
            (await reloadWith({'acceptedTerms': 5})).termsAccepted,
            isFalse,
          );
        },
      );
    });

    test('notifies listeners on change', () async {
      final store = await reload();
      var notified = 0;
      store.addListener(() => notified++);

      await store.save(deviceId, 'Car');
      await store.remove(deviceId);
      await store.acceptTerms();

      expect(notified, 3);
    });
  });
}

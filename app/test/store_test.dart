import 'package:flutter_test/flutter_test.dart';
import 'package:libre_bm6_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const deviceId = 'A1:B2:C3:D4:E5:F6';

Future<Store> reload() async => Store(await SharedPreferences.getInstance());

void main() {
  group('Store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts with the terms not accepted and no devices', () async {
      final store = await reload();

      expect(store.termsAccepted, isFalse);
      expect(store.devices, isEmpty);
    });

    test('persists terms acceptance', () async {
      await (await reload()).acceptTerms();

      expect((await reload()).termsAccepted, isTrue);
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

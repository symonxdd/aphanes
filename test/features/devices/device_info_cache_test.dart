import 'dart:convert';

import 'package:aphanes/core/persistence/key_value_store.dart';
import 'package:aphanes/features/devices/models/device.dart';
import 'package:aphanes/features/devices/models/device_detail.dart';
import 'package:aphanes/features/devices/models/device_info.dart';
import 'package:aphanes/features/devices/models/devmode_status.dart';
import 'package:aphanes/features/devices/services/device_detail_service.dart';
import 'package:aphanes/features/devices/services/device_storage_service.dart';
import 'package:aphanes/features/devices/state/device_detail_controller.dart';
import 'package:aphanes/features/devices/state/device_info_cache_controller.dart';
import 'package:aphanes/features/devices/state/device_list_controller.dart';
import 'package:aphanes/features/devices/state/device_reachability_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the real SSH round trip. Subclassed rather than faked
/// behind an interface because the production provider constructs the
/// real service by default and only the provider override is swapped.
class _StubDetailService extends DeviceDetailService {
  _StubDetailService(this.detail);

  final DeviceDetail detail;

  @override
  Future<DeviceDetail> fetch(Device device) async => detail;
}

/// The same in-memory stand-in the rest of the suite uses for secure
/// storage: the real one has no platform-channel handler under
/// `flutter test` and hangs rather than failing.
class _FakeStore implements SecureKeyValueStore {
  final Map<String, String> values = {};
  int reads = 0;
  int writes = 0;

  @override
  Future<String?> read(String key) async {
    reads++;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

Device _device(String id) => Device(
  id: id,
  name: 'Living room',
  model: 'OLED55',
  host: '192.168.1.5',
  port: 22,
  username: 'prisoner',
  privateKeyPem: 'key',
  pairedAt: DateTime.utc(2026),
);

const DeviceInfo _info = DeviceInfo(
  modelName: 'OLED55C14LB',
  firmwareVersion: '03.30.85',
  webosVersion: '6.0.0',
  otaId: 'HE_DTV_W21H_AFAAABAA',
  socName: 'k5lp',
);

void main() {
  group('DeviceStorageService info cache', () {
    test('round-trips a device info payload', () async {
      final _FakeStore store = _FakeStore();
      final DeviceStorageService service = DeviceStorageService(store);
      await service.save(_device('a'));

      await service.saveInfo('a', _info);

      expect(await service.loadAllInfo(), {'a': _info});
    });

    test('only returns info for devices still in the index', () async {
      final _FakeStore store = _FakeStore();
      final DeviceStorageService service = DeviceStorageService(store);
      await service.save(_device('a'));
      await service.saveInfo('a', _info);

      await service.delete('a');

      expect(await service.loadAllInfo(), isEmpty);
      // The cached payload is gone from storage too, not just unindexed.
      expect(
        store.values.keys.where((String k) => k.contains('info')),
        isEmpty,
      );
    });

    test('stores nothing readable as a device credential', () async {
      final _FakeStore store = _FakeStore();
      final DeviceStorageService service = DeviceStorageService(store);
      await service.save(_device('a'));
      await service.saveInfo('a', _info);

      final Map<String, dynamic> cached =
          jsonDecode(store.values['device_info_a']!) as Map<String, dynamic>;
      expect(cached.keys, isNot(contains('privateKeyPem')));
      expect(cached.keys, isNot(contains('token')));
    });
  });

  group('DeviceInfoCacheController', () {
    ProviderContainer container(_FakeStore store) {
      final ProviderContainer c = ProviderContainer(
        overrides: [
          deviceStorageServiceProvider.overrideWithValue(
            DeviceStorageService(store),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('put persists and exposes the info in memory', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer c = container(store);
      await c.read(deviceInfoCacheProvider.future);

      await c.read(deviceInfoCacheProvider.notifier).put('a', _info);

      expect(c.read(deviceInfoCacheProvider).value, {'a': _info});
      expect(store.values.containsKey('device_info_a'), isTrue);
    });

    test('put skips the write when nothing changed', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer c = container(store);
      await c.read(deviceInfoCacheProvider.future);
      await c.read(deviceInfoCacheProvider.notifier).put('a', _info);
      final int writesAfterFirst = store.writes;

      await c.read(deviceInfoCacheProvider.notifier).put('a', _info);

      expect(store.writes, writesAfterFirst);
    });

    test('put ignores a TV that reported nothing usable', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer c = container(store);
      await c.read(deviceInfoCacheProvider.future);

      await c.read(deviceInfoCacheProvider.notifier).put(
        'a',
        const DeviceInfo(),
      );

      expect(c.read(deviceInfoCacheProvider).value, isEmpty);
      expect(store.writes, 0);
    });

    test('forget drops an unpaired device from the in-memory map', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer c = container(store);
      await c.read(deviceInfoCacheProvider.future);
      await c.read(deviceInfoCacheProvider.notifier).put('a', _info);
      await c.read(deviceInfoCacheProvider.notifier).put('b', _info);

      c.read(deviceInfoCacheProvider.notifier).forget('a');

      expect(c.read(deviceInfoCacheProvider).value, {'b': _info});
    });

    // The write-through in deviceDetailProvider calls this from inside
    // another provider's async build. Riverpod forbids modifying a
    // provider during a *synchronous* build, so this pins down that the
    // post-await case it actually uses is allowed.
    test('can be written from inside another provider build', () async {
      final _FakeStore store = _FakeStore();
      final ProviderContainer c = container(store);
      final FutureProvider<String> writer = FutureProvider<String>((
        Ref ref,
      ) async {
        await Future<void>.delayed(Duration.zero);
        await ref.read(deviceInfoCacheProvider.notifier).put('a', _info);
        return 'done';
      });

      expect(await c.read(writer.future), 'done');
      expect(c.read(deviceInfoCacheProvider).value, {'a': _info});
    });
  });

  group('deviceDetailProvider write-through', () {
    test('stores the facts it fetched, and only the facts', () async {
      final _FakeStore store = _FakeStore();
      final DeviceStorageService storage = DeviceStorageService(store);
      await storage.save(_device('a'));

      final ProviderContainer c = ProviderContainer(
        overrides: [
          deviceStorageServiceProvider.overrideWithValue(storage),
          deviceReachabilityProvider('a').overrideWith((Ref _) async => true),
          deviceDetailServiceProvider.overrideWithValue(
            _StubDetailService(
              const DeviceDetail(
                info: _info,
                devMode: DevModeStatus(
                  token: 'session-token',
                  remaining: '2 hours',
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);

      await c.read(deviceDetailProvider('a').future);
      // The write-through is deliberately not awaited by the provider, so
      // that a storage round trip never sits between a finished fetch and
      // the page hearing about it. Yield until it lands.
      for (int i = 0; i < 20 && store.values['device_info_a'] == null; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      // In memory, ready for the next visit to render immediately.
      expect(c.read(deviceInfoCacheProvider).value, {'a': _info});
      // And on disk, without the Developer Mode session going with it.
      final String stored = store.values['device_info_a']!;
      expect(stored, contains('OLED55C14LB'));
      expect(stored, isNot(contains('session-token')));
      expect(stored, isNot(contains('2 hours')));
    });
  });
}

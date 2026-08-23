import 'dart:async';

import 'package:aphanes/core/persistence/key_value_store.dart';
import 'package:aphanes/core/persistence/secure_storage_provider.dart';
import 'package:aphanes/core/persistence/shared_preferences_provider.dart';
import 'package:aphanes/features/devices/models/device.dart';
import 'package:aphanes/features/devices/models/device_detail.dart';
import 'package:aphanes/features/devices/models/device_info.dart';
import 'package:aphanes/features/devices/models/devmode_status.dart';
import 'package:aphanes/features/devices/services/device_storage_service.dart';
import 'package:aphanes/features/devices/state/device_detail_controller.dart';
import 'package:aphanes/features/devices/state/device_reachability_controller.dart';
import 'package:aphanes/features/devices/ui/device_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

const String _id = 'tv-1';

final Device _device = Device(
  id: _id,
  name: 'Living room',
  model: null,
  host: '192.168.1.5',
  port: 22,
  username: 'prisoner',
  privateKeyPem: 'key',
  pairedAt: DateTime.utc(2026, 3, 4, 10),
);

const DeviceInfo _info = DeviceInfo(
  modelName: 'OLED55C14LB',
  firmwareVersion: '03.30.85',
  webosVersion: '6.0.0',
  otaId: 'HE_DTV_W21H_AFAAABAA',
  socName: 'k5lp',
);

/// Pumps the detail page with the TV reachable and its live fetch left
/// deliberately unfinished, which is the exact window the stored copy
/// exists to fill.
Future<void> _pumpPage(
  WidgetTester tester, {
  required bool seedCache,
  bool reachable = true,
  Completer<DeviceDetail>? fetch,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final _InMemoryKeyValueStore store = _InMemoryKeyValueStore();
  final DeviceStorageService storage = DeviceStorageService(store);
  await storage.save(_device);
  if (seedCache) {
    await storage.saveInfo(_id, _info);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(store),
        deviceReachabilityProvider(
          _id,
        ).overrideWith((Ref _) async => reachable),
        deviceDetailProvider(_id).overrideWith(
          (Ref _) => (fetch ?? Completer<DeviceDetail>()).future,
        ),
      ],
      child: const MaterialApp(home: DeviceDetailPage(deviceId: _id)),
    ),
  );
  // Several pumps, not pumpAndSettle: the fetch is intentionally left
  // hanging, and pumpAndSettle would wait on it forever.
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('a TV opened before shows its details with no spinner', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, seedCache: true);

    expect(find.text('OLED55C14LB'), findsOneWidget);
    expect(find.text('03.30.85'), findsOneWidget);
    expect(find.text('HE_DTV_W21H_AFAAABAA'), findsOneWidget);
    expect(find.text('k5lp'), findsOneWidget);
    // The whole point: the stored copy is on screen while the live fetch
    // is still running, and nothing spins.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The one value that is never served from the cache says so instead.
    expect(find.text('Checking...'), findsOneWidget);
  });

  testWidgets('an unreachable TV with stored facts skips the notice', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, seedCache: true, reachable: false);

    // The facts are still true about this TV, so they stay put.
    expect(find.text('OLED55C14LB'), findsOneWidget);
    expect(find.text('k5lp'), findsOneWidget);
    // Explaining an absence that isn't there would just be noise.
    expect(
      find.textContaining('not reachable', findRichText: true),
      findsNothing,
    );
    // Only the one value that genuinely cannot be shown says so, and it
    // stays a short value in the same column as every other field.
    expect(find.text('Unreachable'), findsOneWidget);
  });

  testWidgets('an unreachable TV with nothing stored shows the notice', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, seedCache: false, reachable: false);

    expect(
      find.textContaining('not reachable', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Unreachable'), findsNothing);
  });

  testWidgets('the renew action is inert until the session is known', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, seedCache: true);

    final IconButton renew = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.refresh),
    );
    expect(renew.onPressed, isNull);
  });

  testWidgets('a first-ever visit still shows a spinner', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, seedCache: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checking Developer Mode session...'), findsNothing);
  });

  // Only what reaches the screen. This test overrides deviceDetailProvider
  // outright, so the write-back that provider performs is not in play
  // here - device_info_cache_test.dart covers that against the real one.
  testWidgets('a completed fetch replaces what the stored copy showed', (
    WidgetTester tester,
  ) async {
    final Completer<DeviceDetail> fetch = Completer<DeviceDetail>();
    await _pumpPage(tester, seedCache: true, fetch: fetch);

    fetch.complete(
      const DeviceDetail(
        info: DeviceInfo(
          modelName: 'OLED55C14LB',
          firmwareVersion: '04.00.10',
          webosVersion: '6.0.0',
          otaId: 'HE_DTV_W21H_AFAAABAA',
          socName: 'k5lp',
        ),
        devMode: DevModeStatus(token: 'abc123', remaining: '2 hours'),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('04.00.10'), findsOneWidget);
    expect(find.text('03.30.85'), findsNothing);
    // "2 hours" parses to a real duration, so the row switches to a
    // ticking clock rather than echoing LG's wording back.
    expect(find.text('2:00:00'), findsOneWidget);
  });
}

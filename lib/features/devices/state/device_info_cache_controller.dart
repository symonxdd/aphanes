import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_info.dart';
import 'device_list_controller.dart';

/// The last hardware/firmware facts fetched from each paired TV, held in
/// memory and backed by secure storage.
///
/// Exists so reopening a device's detail page can show what that TV said
/// last time straight away, instead of a spinner. None of it changes
/// without a firmware update, so a stored copy is very nearly always
/// still correct, and the page re-fetches behind it either way.
///
/// Kept alive for the app's lifetime (no `autoDispose`) on purpose: it is
/// a handful of short strings, and reloading it from the platform
/// keystore every time a detail page opens would give back exactly the
/// delay this is meant to remove.
class DeviceInfoCacheController extends AsyncNotifier<Map<String, DeviceInfo>> {
  @override
  Future<Map<String, DeviceInfo>> build() {
    return ref.watch(deviceStorageServiceProvider).loadAllInfo();
  }

  /// Records what a TV just reported. A no-op when the TV reported
  /// nothing usable, and when it matches what is already stored - which
  /// is the normal outcome, since these facts only move on a firmware
  /// update.
  Future<void> put(String deviceId, DeviceInfo info) async {
    if (info.isEmpty) {
      return;
    }
    final Map<String, DeviceInfo> current = await future;
    if (current[deviceId] == info) {
      return;
    }
    await ref.read(deviceStorageServiceProvider).saveInfo(deviceId, info);
    state = AsyncData(<String, DeviceInfo>{...current, deviceId: info});
  }

  /// Drops an unpaired device's entry. The stored copy is deleted by
  /// `DeviceStorageService.delete` as part of removing the device itself;
  /// this is the in-memory half of the same removal.
  void forget(String deviceId) {
    final Map<String, DeviceInfo>? current = state.value;
    if (current == null || !current.containsKey(deviceId)) {
      return;
    }
    state = AsyncData(
      <String, DeviceInfo>{
        for (final MapEntry<String, DeviceInfo> entry in current.entries)
          if (entry.key != deviceId) entry.key: entry.value,
      },
    );
  }
}

final AsyncNotifierProvider<DeviceInfoCacheController, Map<String, DeviceInfo>>
deviceInfoCacheProvider =
    AsyncNotifierProvider<DeviceInfoCacheController, Map<String, DeviceInfo>>(
      DeviceInfoCacheController.new,
    );

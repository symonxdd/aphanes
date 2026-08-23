import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/secure_storage_provider.dart';
import '../models/device.dart';
import '../services/device_storage_service.dart';
import 'device_info_cache_controller.dart';

final Provider<DeviceStorageService> deviceStorageServiceProvider =
    Provider<DeviceStorageService>(
      (Ref ref) => DeviceStorageService(ref.watch(secureStorageProvider)),
    );

class DeviceListController extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() {
    return ref.watch(deviceStorageServiceProvider).loadAll();
  }

  Future<void> add(Device device) async {
    await ref.read(deviceStorageServiceProvider).save(device);
    state = AsyncData([...await future, device]);
  }

  Future<void> remove(String deviceId) async {
    // Deletes the device record and its cached TV info together.
    await ref.read(deviceStorageServiceProvider).delete(deviceId);
    ref.read(deviceInfoCacheProvider.notifier).forget(deviceId);
    state = AsyncData(
      (await future).where((Device d) => d.id != deviceId).toList(),
    );
  }

  Future<void> rename(String deviceId, String name) async {
    final List<Device> devices = await future;
    final int index = devices.indexWhere((Device d) => d.id == deviceId);
    if (index == -1) {
      return;
    }
    final Device renamed = devices[index].copyWith(name: name);
    await ref.read(deviceStorageServiceProvider).save(renamed);
    state = AsyncData([
      ...devices.sublist(0, index),
      renamed,
      ...devices.sublist(index + 1),
    ]);
  }

  /// Updates a device's stored IP address - the credential from pairing
  /// stays valid regardless, so this is the recovery path for a TV that's
  /// been assigned a new address (e.g. by DHCP), without needing to pair
  /// again from the TV's Developer Mode app.
  Future<void> updateHost(String deviceId, String host) async {
    final List<Device> devices = await future;
    final int index = devices.indexWhere((Device d) => d.id == deviceId);
    if (index == -1) {
      return;
    }
    final Device updated = devices[index].copyWith(host: host);
    await ref.read(deviceStorageServiceProvider).save(updated);
    state = AsyncData([
      ...devices.sublist(0, index),
      updated,
      ...devices.sublist(index + 1),
    ]);
  }
}

final AsyncNotifierProvider<DeviceListController, List<Device>>
deviceListProvider =
    AsyncNotifierProvider<DeviceListController, List<Device>>(
      DeviceListController.new,
    );
